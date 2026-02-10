import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'models/report.dart';
import 'services/firestore_service.dart';
import 'widgets/report_dialog.dart';
import 'web_map_widget.dart' if (dart.library.io) 'web_map_widget_stub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: mapInitSuccess
          ? (kIsWeb
              ? WebNaverMap(clientId: clientId)
              : DeliveryMapScreen(clientId: clientId))
          : const _ErrorScreen(),
    );
  }
}

/// 앱 전용 지도 화면 (제보 기능 포함)
class DeliveryMapScreen extends StatefulWidget {
  final String clientId;
  const DeliveryMapScreen({super.key, required this.clientId});

  @override
  State<DeliveryMapScreen> createState() => _DeliveryMapScreenState();
}

class _DeliveryMapScreenState extends State<DeliveryMapScreen> {
  final _firestoreService = FirestoreService();
  NaverMapController? _mapController;
  NOverlayImage? _redIcon;
  NOverlayImage? _greenIcon;

  @override
  Widget build(BuildContext context) {
    const seoulCityHall = NLatLng(37.5665, 126.9780);
    final safeAreaPadding = MediaQuery.paddingOf(context);

    return Scaffold(
      appBar: AppBar(title: const Text('배달 지도')),
      body: NaverMap(
        options: NaverMapViewOptions(
          contentPadding: safeAreaPadding,
          initialCameraPosition: NCameraPosition(
            target: seoulCityHall,
            zoom: 15,
          ),
        ),
        onMapReady: (controller) async {
          _mapController = controller;

          // 커스텀 아이콘 미리 생성
          _redIcon = await NOverlayImage.fromWidget(
            widget: const _MarkerWidget(color: Colors.red),
            size: const Size(48, 48),
            context: context,
          );
          _greenIcon = await NOverlayImage.fromWidget(
            widget: const _MarkerWidget(color: Colors.green),
            size: const Size(48, 48),
            context: context,
          );

          // Firestore에서 기존 제보 불러오기
          _loadReports();
          debugPrint("Naver map is ready!");
        },
        onMapTapped: (point, latLng) {
          // 일반 탭은 무시 (정보창 닫기 등)
        },
        onMapLongTapped: (point, latLng) async {
          // 롱프레스 → 제보 다이얼로그
          final report = await ReportDialog.show(
            context,
            latitude: latLng.latitude,
            longitude: latLng.longitude,
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
        },
      ),
    );
  }

  /// Firestore에서 제보 데이터를 불러와 마커로 표시
  Future<void> _loadReports() async {
    if (_mapController == null || _redIcon == null || _greenIcon == null) return;

    final reports = await _firestoreService.getReports();

    // 기존 마커 제거 후 새로 추가
    _mapController!.clearOverlays();

    final markers = <NMarker>{};
    for (final report in reports) {
      final isResident = report.type == ReportType.residentOnly;
      final marker = NMarker(
        id: report.id ?? 'report_${report.createdAt.millisecondsSinceEpoch}',
        position: NLatLng(report.latitude, report.longitude),
        icon: isResident ? _redIcon! : _greenIcon!,
        caption: NOverlayCaption(
          text: isResident ? '입주민 전용(진입금지)' : '방문자 전용(진입가능)',
          color: Colors.black,
          haloColor: Colors.white,
          textSize: 12,
        ),
      );

      // 마커 클릭 시 상세 정보 보여주기
      marker.setOnTapListener((overlay) {
        final title = isResident ? '🔴 입주민 전용 (진입금지)' : '🟢 배달원 전용 (진입가능)';
        final desc = report.description.isNotEmpty
            ? report.description
            : (isResident ? '배달 오토바이 진입이 불가능합니다.' : '배달 오토바이 진입이 가능합니다.');

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 12),
                Text(
                  '위치: (${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)})',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      });

      markers.add(marker);
    }

    _mapController!.addOverlayAll(markers);
  }
}

/// 지도 초기화 실패 화면
class _ErrorScreen extends StatelessWidget {
  const _ErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('배달 지도')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              '지도 초기화 실패',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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