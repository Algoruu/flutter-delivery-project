import 'package:flutter/material.dart';
import 'package:flutter_naver_map_web/flutter_naver_map_web.dart';
import 'dart:js_interop';

@JS('naver.maps.Event.addListener')
external JSAny _addNaverListener(JSAny target, JSString eventName, JSFunction callback);

@JS('document.addEventListener')
external void _addDocListener(JSString type, JSFunction callback);

extension type _JSKeyboardEvent(JSObject _) implements JSObject {
  external JSString get key;
}

class WebNaverMap extends StatefulWidget {
  final String clientId;
  const WebNaverMap({super.key, required this.clientId});

  @override
  State<WebNaverMap> createState() => _WebNaverMapState();
}

class _WebNaverMapState extends State<WebNaverMap> {
  final _navMapKey = GlobalKey();

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

  @override
  Widget build(BuildContext context) {
    return NaverMapWeb(
      key: _navMapKey,
      clientId: widget.clientId,
      initialLatitude: 37.5665,
      initialLongitude: 126.9780,
      initialZoom: 15,
      zoomControl: true,
      mapDataControl: true,
      places: [
        // 입주민 전용 마커 (빨간색)
        Place(
          id: 'resident_only',
          name: '입주민 전용(진입금지)',
          latitude: 37.5669,
          longitude: 126.9778,
          description: '이 건물은 입주민만 출입 가능합니다',
          category: '입주민전용',
          iconUrl: 'https://maps.google.com/mapfiles/ms/icons/red-dot.png',
        ),
        // 배달원 전용 마커 (초록색)
        Place(
          id: 'delivery_only',
          name: '배달원 전용(진입가능)',
          latitude: 37.5659,
          longitude: 126.9786,
          description: '배달원이 진입 가능한 건물입니다',
          category: '배달가능',
          iconUrl: 'https://maps.google.com/mapfiles/ms/icons/green-dot.png',
        ),
      ],
      onMapReady: (NaverMap map) {
        // 지도 클릭 시 정보창 닫기
        _addNaverListener(
          map as JSAny,
          'click'.toJS,
          (() => _closeInfoWindows()).toJS,
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
