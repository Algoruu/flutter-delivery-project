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
                    onMapReady: (controller) {
                      final marker = NMarker(
                        id: "delivery_location",
                        position: seoulCityHall,
                        caption: NOverlayCaption(text: "배달 지점"),
                      );
                      controller.addOverlay(marker);
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