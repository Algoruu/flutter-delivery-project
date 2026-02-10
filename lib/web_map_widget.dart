import 'package:flutter/material.dart';
import 'package:flutter_naver_map_web/flutter_naver_map_web.dart';

class WebNaverMap extends StatelessWidget {
  final String clientId;
  const WebNaverMap({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return NaverMapWeb(
      clientId: clientId,
      initialLatitude: 37.5665,
      initialLongitude: 126.9780,
      initialZoom: 15,
      zoomControl: true,
      mapDataControl: true,
      places: [
        Place(
          id: 'delivery_location',
          name: '배달 지점',
          latitude: 37.5665,
          longitude: 126.9780,
          description: '배달 서비스 센터',
          category: '배달',
        ),
      ],
      onMapReady: (NaverMap map) {
        print('Web Naver map is ready!');
      },
      onMarkerClick: (Place place) {
        print('마커 클릭: ${place.name}');
      },
    );
  }
}
