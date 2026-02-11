import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// 네이버 검색 API (지역 검색)를 사용한 장소 검색 서비스
/// developers.naver.com에서 발급받은 Client ID/Secret 필요
class PlaceSearchService {
  final String naverSearchClientId;
  final String naverSearchClientSecret;
  final String ncloudClientId;
  final String ncloudClientSecret;

  PlaceSearchService({
    required this.naverSearchClientId,
    required this.naverSearchClientSecret,
    required this.ncloudClientId,
    required this.ncloudClientSecret,
  });

  /// 키워드로 장소 검색 → 결과에 좌표 포함
  /// 네이버 지역 검색 API + Geocoding API 조합
  Future<List<PlaceSearchResult>> search(String query) async {
    if (query.trim().isEmpty) return [];

    // 1) 네이버 검색 API 키가 있으면 지역 검색 시도
    if (naverSearchClientId.isNotEmpty && naverSearchClientSecret.isNotEmpty) {
      final localResults = await _searchLocal(query);
      if (localResults.isNotEmpty) return localResults;
    }

    // 2) 지역 검색 결과 없으면 Geocoding API로 주소 검색
    final geocodeResults = await _searchGeocode(query);
    return geocodeResults;
  }

  /// 네이버 지역 검색 API (developers.naver.com)
  Future<List<PlaceSearchResult>> _searchLocal(String query) async {
    final uri = Uri.parse(
      'https://openapi.naver.com/v1/search/local.json'
      '?query=${Uri.encodeComponent(query)}&display=5',
    );

    try {
      final response = await http.get(uri, headers: {
        'X-Naver-Client-Id': naverSearchClientId,
        'X-Naver-Client-Secret': naverSearchClientSecret,
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];
        debugPrint('[PlaceSearch] 지역 검색: "$query" → ${items.length}건');

        final results = <PlaceSearchResult>[];
        for (final item in items) {
          final i = item as Map<String, dynamic>;
          final title = _stripHtml(i['title']?.toString() ?? '');
          final roadAddress = i['roadAddress']?.toString() ?? '';
          final jibunAddress = i['address']?.toString() ?? '';
          final category = i['category']?.toString() ?? '';

          // 주소로 좌표 조회 (Geocoding API)
          final address = roadAddress.isNotEmpty ? roadAddress : jibunAddress;
          final coords = await _geocodeAddress(address);

          if (coords != null) {
            results.add(PlaceSearchResult(
              placeName: title,
              roadAddress: roadAddress,
              jibunAddress: jibunAddress,
              category: category,
              latitude: coords.$1,
              longitude: coords.$2,
              isPlace: true,
            ));
          }
        }
        return results;
      } else {
        debugPrint('[PlaceSearch] 지역 검색 오류: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('[PlaceSearch] 지역 검색 예외: $e');
      return [];
    }
  }

  /// Geocoding API로 주소 → 좌표 변환  
  Future<(double, double)?> _geocodeAddress(String address) async {
    if (address.isEmpty) return null;

    final uri = Uri.parse(
      'https://maps.apigw.ntruss.com/map-geocode/v2/geocode'
      '?query=${Uri.encodeComponent(address)}',
    );

    try {
      final response = await http.get(uri, headers: {
        'X-NCP-APIGW-API-KEY-ID': ncloudClientId,
        'X-NCP-APIGW-API-KEY': ncloudClientSecret,
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final addresses = data['addresses'] as List<dynamic>? ?? [];
        if (addresses.isNotEmpty) {
          final a = addresses[0] as Map<String, dynamic>;
          final lat = double.tryParse(a['y']?.toString() ?? '') ?? 0;
          final lng = double.tryParse(a['x']?.toString() ?? '') ?? 0;
          if (lat != 0 && lng != 0) return (lat, lng);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Geocoding API로 주소 검색 (직접 주소 입력 시)
  Future<List<PlaceSearchResult>> _searchGeocode(String query) async {
    final uri = Uri.parse(
      'https://maps.apigw.ntruss.com/map-geocode/v2/geocode'
      '?query=${Uri.encodeComponent(query)}',
    );

    try {
      final response = await http.get(uri, headers: {
        'X-NCP-APIGW-API-KEY-ID': ncloudClientId,
        'X-NCP-APIGW-API-KEY': ncloudClientSecret,
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final addresses = data['addresses'] as List<dynamic>? ?? [];
        debugPrint('[PlaceSearch] Geocoding: "$query" → ${addresses.length}건');

        return addresses.map((addr) {
          final a = addr as Map<String, dynamic>;
          final road = a['roadAddress']?.toString() ?? '';
          final jibun = a['jibunAddress']?.toString() ?? '';
          return PlaceSearchResult(
            placeName: '',
            roadAddress: road,
            jibunAddress: jibun,
            category: '',
            latitude: double.tryParse(a['y']?.toString() ?? '') ?? 0,
            longitude: double.tryParse(a['x']?.toString() ?? '') ?? 0,
            isPlace: false,
          );
        }).toList();
      } else {
        debugPrint('[PlaceSearch] Geocoding 오류: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[PlaceSearch] Geocoding 예외: $e');
      return [];
    }
  }

  /// HTML 태그 제거 (네이버 검색 API는 <b> 태그를 포함)
  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
}

/// 통합 검색 결과 모델
class PlaceSearchResult {
  final String placeName;
  final String roadAddress;
  final String jibunAddress;
  final String category;
  final double latitude;
  final double longitude;
  final bool isPlace; // 장소 검색 결과인지 주소 검색 결과인지

  PlaceSearchResult({
    required this.placeName,
    required this.roadAddress,
    required this.jibunAddress,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.isPlace,
  });

  /// 표시용 제목 (장소명 우선, 없으면 도로명 주소)
  String get displayTitle =>
      placeName.isNotEmpty ? placeName : (roadAddress.isNotEmpty ? roadAddress : jibunAddress);

  /// 표시용 부제 (장소일 때 주소 표시)
  String get displaySubtitle {
    if (isPlace) {
      return roadAddress.isNotEmpty ? roadAddress : jibunAddress;
    }
    // 주소 검색 결과일 때 지번 주소 보조 표시
    return (jibunAddress.isNotEmpty && roadAddress.isNotEmpty) ? jibunAddress : '';
  }

  /// 표시용 주소
  String get displayAddress =>
      roadAddress.isNotEmpty ? roadAddress : jibunAddress;
}
