import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map_web/flutter_naver_map_web.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:js_interop';
import 'models/report.dart';
import 'services/firestore_service.dart';
import 'services/place_search_service.dart';
import 'theme.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/report_dialog.dart';

@JS('naver.maps.Event.addListener')
external JSAny _addNaverListener(JSAny target, JSString eventName, JSFunction callback);

@JS('document.addEventListener')
external void _addDocListener(JSString type, JSFunction callback);

// JS interop for map camera control
@JS('naver.maps.LatLng')
extension type _JSLatLng._(JSObject _) implements JSObject {
  external factory _JSLatLng(JSNumber lat, JSNumber lng);
  external JSNumber lat();
  external JSNumber lng();
}

extension type _JSKeyboardEvent(JSObject _) implements JSObject {
  external JSString get key;
}

extension type _JSMapEvent(JSObject _) implements JSObject {
  external JSObject get coord;
}

extension type _JSCoord(JSObject _) implements JSObject {
  external JSNumber get y;
  external JSNumber get x;
}

// Map object interop
extension type _JSNaverMap(JSObject _) implements JSObject {
  external void setCenter(JSObject latlng);
  external void setZoom(JSNumber zoom);
  external JSObject getCenter();
}

class WebNaverMap extends StatefulWidget {
  final String clientId;
  const WebNaverMap({super.key, required this.clientId});

  @override
  State<WebNaverMap> createState() => _WebNaverMapState();
}

class _WebNaverMapState extends State<WebNaverMap> {
  final _navMapKey = GlobalKey();
  final _firestoreService = FirestoreService();
  late final PlaceSearchService _searchService;
  List<Report> _reports = [];
  bool _isPinAdjustMode = false;
  JSObject? _mapInstance; // 네이버 맵 JS 객체

  @override
  void initState() {
    super.initState();
    _searchService = PlaceSearchService(
      naverSearchClientId: dotenv.env['NAVER_SEARCH_CLIENT_ID'] ?? '',
      naverSearchClientSecret: dotenv.env['NAVER_SEARCH_CLIENT_SECRET'] ?? '',
      ncloudClientId: dotenv.env['CLIENT_ID'] ?? '',
      ncloudClientSecret: dotenv.env['CLIENT_SECRET'] ?? '',
    );
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await _firestoreService.getReports();
      debugPrint('[WebMap] Firestore 제보 로드: ${reports.length}건');
      if (mounted) {
        setState(() => _reports = reports);
      }
    } catch (e) {
      debugPrint('[WebMap] Firestore 로드 오류: $e');
    }
  }

  void _closeInfoWindows() {
    try {
      final state = _navMapKey.currentState;
      if (state != null) {
        (state as dynamic).closeAllInfoWindows();
      }
    } catch (e) {
      debugPrint('Info window close: $e');
    }
  }

  Future<void> _showReportDialog(double lat, double lng) async {
    final report = await ReportDialog.show(
      context,
      latitude: lat,
      longitude: lng,
    );
    if (report != null) {
      await _firestoreService.addReport(report);
      _loadReports();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('제보가 등록되었습니다!',
                  style: GoogleFonts.notoSansKr(color: Colors.white)),
              ],
            ),
            backgroundColor: AppTheme.safeColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 검색 결과 선택 → 카메라 이동 → 핀 조정 모드
  void _onSearchResultSelected(PlaceSearchResult result) {
    // JS API로 카메라 이동
    if (_mapInstance != null) {
      final center = _JSLatLng(result.latitude.toJS, result.longitude.toJS);
      _JSNaverMap(_mapInstance!).setCenter(center);
      _JSNaverMap(_mapInstance!).setZoom(17.toJS);
    }

    setState(() => _isPinAdjustMode = true);
  }

  void _cancelPinAdjust() {
    setState(() => _isPinAdjustMode = false);
  }

  void _confirmPinPosition() {
    if (_mapInstance == null) return;

    // 현재 지도 중심 좌표 가져오기
    final jsCenter = _JSNaverMap(_mapInstance!).getCenter();
    final center = _JSLatLng._(jsCenter);
    final lat = center.lat().toDartDouble;
    final lng = center.lng().toDartDouble;

    setState(() => _isPinAdjustMode = false);

    _showReportDialog(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    // SVG 아이콘 (data URI - 외부 URL 대신 인라인으로 사용하여 CORS 문제 방지)
    const redPinSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="36" viewBox="0 0 24 36"><path d="M12 0C5.4 0 0 5.4 0 12c0 9 12 24 12 24s12-15 12-24C24 5.4 18.6 0 12 0z" fill="%23E53935"/><circle cx="12" cy="12" r="5" fill="white"/></svg>''';
    const greenPinSvg = '''<svg xmlns="http://www.w3.org/2000/svg" width="24" height="36" viewBox="0 0 24 36"><path d="M12 0C5.4 0 0 5.4 0 12c0 9 12 24 12 24s12-15 12-24C24 5.4 18.6 0 12 0z" fill="%2343A047"/><circle cx="12" cy="12" r="5" fill="white"/></svg>''';

    // Firestore 제보 데이터를 Place 목록으로 변환
    final places = _reports.map((report) {
      final isResident = report.type == ReportType.residentOnly;
      return Place(
        id: report.id ?? 'report_${report.createdAt.millisecondsSinceEpoch}',
        name: isResident ? '입주민 전용(진입금지)' : '방문자 전용(진입가능)',
        latitude: report.latitude,
        longitude: report.longitude,
        description: report.description.isNotEmpty
            ? report.description
            : (isResident ? '배달 오토바이 진입 불가' : '배달 오토바이 진입 가능'),
        category: isResident ? '입주민전용' : '배달가능',
        iconUrl: 'data:image/svg+xml,${isResident ? redPinSvg : greenPinSvg}',
      );
    }).toList();

    debugPrint('[WebMap] build: ${places.length}개 마커 전달');

    return Stack(
      children: [
        // 네이버 지도
        NaverMapWeb(
          key: _navMapKey,
          clientId: widget.clientId,
          initialLatitude: 37.5665,
          initialLongitude: 126.9780,
          initialZoom: 15,
          zoomControl: true,
          mapDataControl: true,
          places: places,
          onMapReady: (NaverMap map) {
            _mapInstance = map as JSObject;

            _addNaverListener(
              map as JSAny,
              'click'.toJS,
              (() => _closeInfoWindows()).toJS,
            );

            _addNaverListener(
              map as JSAny,
              'rightclick'.toJS,
              ((JSAny e) {
                final mapEvent = _JSMapEvent(e as JSObject);
                final coord = _JSCoord(mapEvent.coord);
                final lat = coord.y.toDartDouble;
                final lng = coord.x.toDartDouble;
                _showReportDialog(lat, lng);
              }).toJS,
            );

            _addDocListener(
              'keydown'.toJS,
              ((JSAny event) {
                final keyEvent = _JSKeyboardEvent(event as JSObject);
                if (keyEvent.key.toDart == 'Escape') {
                  _closeInfoWindows();
                  if (_isPinAdjustMode) {
                    setState(() => _isPinAdjustMode = false);
                  }
                }
              }).toJS,
            );

            debugPrint('Web Naver map is ready!');
          },
          onMarkerClick: (Place place) {
            debugPrint('마커 클릭: ${place.name}');
          },
        ),

        // 핀 조정 모드: 중앙 핀
        if (_isPinAdjustMode)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Icon(
                Icons.location_on,
                color: AppTheme.primaryColor,
                size: 48,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),

        // 핀 조정 모드: 안내 + 버튼
        if (_isPinAdjustMode)
          Positioned(
            bottom: 32,
            left: 16,
            right: 16,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '지도를 움직여 정확한 위치를 지정하세요',
                        style: GoogleFonts.notoSansKr(
                          fontSize: 13,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _cancelPinAdjust,
                            icon: const Icon(Icons.close),
                            label: const Text('취소'),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: _confirmPinPosition,
                            icon: const Icon(Icons.check),
                            label: const Text('이 위치에 제보하기'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

        // 검색 바 (핀 조정 모드에서는 숨김)
        if (!_isPinAdjustMode)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SafeArea(
                  child: MapSearchBar(
                    searchService: _searchService,
                    onResultSelected: _onSearchResultSelected,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
