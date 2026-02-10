import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'web_map_widget.dart' if (dart.library.io) 'web_map_widget_stub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const clientId = 'ssogztqxcd';
  bool mapInitSuccess = false;

  if (!kIsWeb) {
    try {
      await FlutterNaverMap().init(
        clientId: clientId,
        onAuthFailed: (ex) {
          switch (ex) {
            case NQuotaExceededException(:final message):
              print("사용량 초과 (message: $message)");
            case NUnauthorizedClientException() ||
                  NClientUnspecifiedException() ||
                  NAnotherAuthFailedException():
              print("인증 실패: $ex");
          }
        },
      );
      mapInitSuccess = true;
    } catch (e) {
      print("지도 초기화 실패: $e");
      mapInitSuccess = false;
    }
  } else {
    mapInitSuccess = true;
  }

  runApp(MyApp(clientId: clientId, mapInitSuccess: mapInitSuccess));
}


class MyApp extends StatelessWidget {
  final String clientId;
  final bool mapInitSuccess;

  const MyApp({
    super.key,
    required this.clientId,
    required this.mapInitSuccess,
  });

  @override
  Widget build(BuildContext context) {
    const seoulCityHall = NLatLng(37.5665, 126.9780);
    final safeAreaPadding = MediaQuery.paddingOf(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('배달 지도')),
        body: mapInitSuccess
            ? (kIsWeb
                ? WebNaverMap(clientId: clientId)
                : NaverMap(
                    options: NaverMapViewOptions(
                      contentPadding: safeAreaPadding,
                      initialCameraPosition: NCameraPosition(
                        target: seoulCityHall,
                        zoom: 15,
                      ),
                    ),
                    onMapReady: (controller) async {
                      // 입주민 전용 마커 (빨간색)
                      final residentIcon = await NOverlayImage.fromWidget(
                        widget: _MarkerWidget(color: Colors.red),
                        size: const Size(48, 48),
                        context: context,
                      );
                      
                      final residentMarker = NMarker(
                        id: "resident_only",
                        position: const NLatLng(37.5669, 126.9778),
                        icon: residentIcon,
                        caption: NOverlayCaption(
                          text: "입주민 전용(진입금지)",
                          color: Colors.black,
                          haloColor: Colors.white,
                          textSize: 12,
                        ),
                      );

                      // 배달원 전용 마커 (초록색)
                      final deliveryIcon = await NOverlayImage.fromWidget(
                        widget: _MarkerWidget(color: Colors.green),
                        size: const Size(48, 48),
                        context: context,
                      );
                      
                      final deliveryMarker = NMarker(
                        id: "delivery_only",
                        position: const NLatLng(37.5659, 126.9786),
                        icon: deliveryIcon,
                        caption: NOverlayCaption(
                          text: "배달원 전용(진입가능)",
                          color: Colors.black,
                          haloColor: Colors.white,
                          textSize: 12,
                        ),
                      );

                      controller.addOverlayAll({
                        residentMarker,
                        deliveryMarker,
                      });
                      print("Naver map is ready!");
                    },
                  ))
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    const Text(
                      '지도 초기화 실패',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '네이버 클라우드 플랫폼에서\n클라이언트 ID를 등록해주세요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh),
                      label: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

// 네이버 마커와 비슷한 커스텀 마커 위젯
class _MarkerWidget extends StatelessWidget {
  final Color color;

  const _MarkerWidget({required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // 마커 핀 모양
        Icon(
          Icons.location_on,
          color: color,
          size: 48,
        ),
        // 중앙의 흰색 원
        Positioned(
          top: 8,
          child: Container(
            width: 16,
            height: 16,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}