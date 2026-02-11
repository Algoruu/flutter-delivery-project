// 웹 개발용 CORS 프록시 서버
// 사용법: dart run tools/cors_proxy.dart
//
// 웹 브라우저에서는 네이버 API를 직접 호출할 수 없습니다 (CORS 차단).
// 이 프록시 서버를 통해 API 요청을 중계합니다.
//
// 프록시 URL 형식:
//   http://localhost:3456/proxy?url=<인코딩된_원본_URL>
//   요청 헤더는 그대로 전달됩니다.

import 'dart:io';
import 'dart:typed_data';

void main() async {
  final port = 3456;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  print('===========================================');
  print('  CORS Proxy Server running');
  print('  http://localhost:$port');
  print('===========================================');
  print('');

  await for (final request in server) {
    _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  // 모든 응답에 CORS 헤더 추가
  request.response.headers
    ..add('Access-Control-Allow-Origin', '*')
    ..add('Access-Control-Allow-Headers', '*')
    ..add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    ..add('Access-Control-Max-Age', '86400');

  // OPTIONS 프리플라이트 요청 처리
  if (request.method == 'OPTIONS') {
    request.response.statusCode = 200;
    await request.response.close();
    return;
  }

  // /proxy 경로만 처리
  if (!request.uri.path.startsWith('/proxy')) {
    request.response
      ..statusCode = 404
      ..write('Use /proxy?url=<target_url>');
    await request.response.close();
    return;
  }

  // 타겟 URL 추출
  final targetUrl = request.uri.queryParameters['url'];
  if (targetUrl == null || targetUrl.isEmpty) {
    request.response
      ..statusCode = 400
      ..write('Missing "url" query parameter');
    await request.response.close();
    return;
  }

  try {
    final client = HttpClient();
    final uri = Uri.parse(targetUrl);
    final proxyReq = await client.openUrl(request.method, uri);

    // 원본 요청 헤더 전달 (일부 제외)
    const skipHeaders = {
      'host', 'origin', 'referer', 'connection',
      'accept-encoding', 'sec-fetch-mode', 'sec-fetch-site',
      'sec-fetch-dest', 'sec-ch-ua', 'sec-ch-ua-mobile',
      'sec-ch-ua-platform',
    };

    request.headers.forEach((name, values) {
      if (!skipHeaders.contains(name.toLowerCase())) {
        for (final v in values) {
          proxyReq.headers.add(name, v);
        }
      }
    });

    // Accept 헤더 보장
    proxyReq.headers.set('Accept', 'application/json');

    final proxyRes = await proxyReq.close();

    // 응답 본문을 먼저 전부 읽기 (pipe 대신 버퍼링)
    final chunks = <List<int>>[];
    await for (final chunk in proxyRes) {
      chunks.add(chunk);
    }
    final bodyBytes = BytesBuilder();
    for (final c in chunks) {
      bodyBytes.add(c);
    }
    final body = bodyBytes.toBytes();

    // 응답 상태 코드 전달
    request.response.statusCode = proxyRes.statusCode;

    // Content-Type만 전달 (Content-Length는 실제 바이트 기준으로 재설정)
    final contentType = proxyRes.headers.contentType;
    if (contentType != null) {
      request.response.headers.contentType = contentType;
    }

    // 실제 바이트 길이로 Content-Length 설정
    request.response.headers.contentLength = body.length;

    // 응답 본문 전송
    request.response.add(body);
    await request.response.close();
    client.close();

    print('[${request.method}] $targetUrl → ${proxyRes.statusCode} (${body.length} bytes)');
  } catch (e) {
    print('[ERROR] $targetUrl → $e');
    try {
      request.response
        ..statusCode = 502
        ..write('Proxy error: $e');
      await request.response.close();
    } catch (_) {
      // 이미 응답이 시작된 경우 무시
    }
  }
}
