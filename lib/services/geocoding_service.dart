import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 네이버 Geocoding API를 사용한 주소 검색 서비스
class GeocodingService {
  final String clientId;
  final String clientSecret;

  GeocodingService({
    required this.clientId,
    required this.clientSecret,
  });

  /// 주소 → 좌표 (Geocoding)
  /// 네이버 클라우드 플랫폼 Geocoding API 사용
  Future<List<SearchResult>> searchAddress(String query) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(
      'https://maps.apigw.ntruss.com/map-geocode/v2/geocode'
      '?query=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(uri, headers: {
        'X-NCP-APIGW-API-KEY-ID': clientId,
        'X-NCP-APIGW-API-KEY': clientSecret,
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final addresses = data['addresses'] as List<dynamic>? ?? [];
        debugPrint('[Geocoding] 검색: "$query" → 결과 ${addresses.length}건');

        return addresses.map((addr) {
          final a = addr as Map<String, dynamic>;
          return SearchResult(
            address: a['roadAddress']?.toString() ?? a['jibunAddress']?.toString() ?? '',
            jibunAddress: a['jibunAddress']?.toString() ?? '',
            roadAddress: a['roadAddress']?.toString() ?? '',
            latitude: double.tryParse(a['y']?.toString() ?? '') ?? 0,
            longitude: double.tryParse(a['x']?.toString() ?? '') ?? 0,
          );
        }).toList();
      } else {
        debugPrint('[Geocoding] API 오류: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('[Geocoding] 예외 발생: $e');
      return [];
    }
  }
}

/// 검색 결과 모델
class SearchResult {
  final String address;
  final String jibunAddress;
  final String roadAddress;
  final double latitude;
  final double longitude;

  SearchResult({
    required this.address,
    required this.jibunAddress,
    required this.roadAddress,
    required this.latitude,
    required this.longitude,
  });

  /// 표시용 주소 (도로명 주소 우선)
  String get displayAddress =>
      roadAddress.isNotEmpty ? roadAddress : jibunAddress;
}
