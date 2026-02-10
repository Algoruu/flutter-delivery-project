import 'package:flutter/material.dart';
import 'package:flutter_naver_map_web/flutter_naver_map_web.dart';
import 'dart:js_interop';
import 'models/report.dart';
import 'services/firestore_service.dart';
import 'widgets/report_dialog.dart';

@JS('naver.maps.Event.addListener')
external JSAny _addNaverListener(JSAny target, JSString eventName, JSFunction callback);

@JS('document.addEventListener')
external void _addDocListener(JSString type, JSFunction callback);

extension type _JSKeyboardEvent(JSObject _) implements JSObject {
  external JSString get key;
}

// 우클릭 이벤트에서 좌표 추출용 JS interop
extension type _JSMapEvent(JSObject _) implements JSObject {
  external JSObject get coord;
}

extension type _JSCoord(JSObject _) implements JSObject {
  external JSNumber get y; // latitude
  external JSNumber get x; // longitude
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
  List<Report> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    final reports = await _firestoreService.getReports();
    if (mounted) {
      setState(() => _reports = reports);
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
      _loadReports(); // 마커 새로고침
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ 제보가 등록되었습니다!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
        iconUrl: isResident
            ? 'https://maps.google.com/mapfiles/ms/icons/red-dot.png'
            : 'https://maps.google.com/mapfiles/ms/icons/green-dot.png',
      );
    }).toList();

    return NaverMapWeb(
      key: _navMapKey,
      clientId: widget.clientId,
      initialLatitude: 37.5665,
      initialLongitude: 126.9780,
      initialZoom: 15,
      zoomControl: true,
      mapDataControl: true,
      places: places,
      onMapReady: (NaverMap map) {
        // 지도 클릭 시 정보창 닫기
        _addNaverListener(
          map as JSAny,
          'click'.toJS,
          (() => _closeInfoWindows()).toJS,
        );

        // 지도 우클릭(롱프레스 대체) → 제보 기능
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

        // ESC 키로 정보창 닫기
        _addDocListener(
          'keydown'.toJS,
          ((JSAny event) {
            final keyEvent = _JSKeyboardEvent(event as JSObject);
            if (keyEvent.key.toDart == 'Escape') {
              _closeInfoWindows();
            }
          }).toJS,
        );

        debugPrint('Web Naver map is ready!');
      },
      onMarkerClick: (Place place) {
        debugPrint('마커 클릭: ${place.name}');
      },
    );
  }
}
