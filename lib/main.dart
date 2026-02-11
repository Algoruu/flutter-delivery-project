import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'models/report.dart';
import 'services/firestore_service.dart';
import 'services/place_search_service.dart';
import 'theme.dart';
import 'widgets/map_search_bar.dart';
import 'widgets/report_dialog.dart';
import 'web_map_widget.dart' if (dart.library.io) 'web_map_widget_stub.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 로드
  await dotenv.load(fileName: '.env');

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final clientId = dotenv.env['CLIENT_ID'] ?? '';
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
      title: '배달 지도',
      theme: AppTheme.lightTheme,
      home: mapInitSuccess
          ? (kIsWeb
              ? Scaffold(
                  appBar: AppBar(
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delivery_dining, size: 24),
                        const SizedBox(width: 8),
                        const Text('배달 지도'),
                      ],
                    ),
                  ),
                  body: WebNaverMap(clientId: clientId),
                )
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
  late final PlaceSearchService _searchService;
  NMarker? _searchMarker;
  bool _isPinAdjustMode = false; // 핀 위치 조정 모드

  @override
  void initState() {
    super.initState();
    _searchService = PlaceSearchService(
      // 네이버 검색 API (developers.naver.com) — 장소명 검색용
      naverSearchClientId: dotenv.env['NAVER_SEARCH_CLIENT_ID'] ?? '',
      naverSearchClientSecret: dotenv.env['NAVER_SEARCH_CLIENT_SECRET'] ?? '',
      // NCloud Maps Geocoding API — 주소 검색 및 좌표 변환용
      ncloudClientId: dotenv.env['CLIENT_ID'] ?? '',
      ncloudClientSecret: dotenv.env['CLIENT_SECRET'] ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    const seoulCityHall = NLatLng(37.5665, 126.9780);
    final safeAreaPadding = MediaQuery.paddingOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delivery_dining, size: 24),
            const SizedBox(width: 8),
            const Text('배달 지도'),
          ],
        ),
      ),
      body: Stack(
        children: [
          NaverMap(
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
        },
      ),

          // 핀 조정 모드: 화면 중앙 핀 표시
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

          // 핀 조정 모드: 안내 + 확인/취소 버튼
          if (_isPinAdjustMode)
            Positioned(
              bottom: 32,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 안내 텍스트
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
                  // 버튼
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

          // 검색 바 오버레이 (핀 조정 모드에서는 숨김)
          if (!_isPinAdjustMode)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: MapSearchBar(
                  searchService: _searchService,
                  onResultSelected: _onSearchResultSelected,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 검색 결과 선택 시 해당 위치로 이동 후 핀 조정 모드 진입
  void _onSearchResultSelected(PlaceSearchResult result) async {
    if (_mapController == null) return;

    final target = NLatLng(result.latitude, result.longitude);

    // 기존 검색 마커 제거
    if (_searchMarker != null) {
      _mapController!.deleteOverlay(_searchMarker!.info);
      _searchMarker = null;
    }

    // 카메라 이동
    await _mapController!.updateCamera(
      NCameraUpdate.scrollAndZoomTo(
        target: target,
        zoom: 17,
      )..setAnimation(
        animation: NCameraAnimation.easing,
        duration: const Duration(milliseconds: 500),
      ),
    );

    // 핀 조정 모드 진입
    if (mounted) {
      setState(() => _isPinAdjustMode = true);
    }
  }

  /// 핀 조정 취소
  void _cancelPinAdjust() {
    setState(() => _isPinAdjustMode = false);
  }

  /// 핀 위치 확정 → 제보 다이얼로그
  void _confirmPinPosition() async {
    if (_mapController == null) return;

    // 현재 카메라 중심 좌표 가져오기
    final cameraPosition = await _mapController!.getCameraPosition();
    final center = cameraPosition.target;

    setState(() => _isPinAdjustMode = false);

    if (!mounted) return;
    final report = await ReportDialog.show(
      context,
      latitude: center.latitude,
      longitude: center.longitude,
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
        final statusColor = isResident ? AppTheme.dangerColor : AppTheme.safeColor;
        final statusIcon = isResident ? Icons.block : Icons.check_circle;
        final statusLabel = isResident ? '입주민 전용 (진입금지)' : '방문자 전용 (진입가능)';
        final desc = report.description.isNotEmpty
            ? report.description
            : (isResident ? '배달 오토바이 진입이 불가능합니다.' : '배달 오토바이 진입이 가능합니다.');

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상태 헤더
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          statusLabel,
                          style: GoogleFonts.notoSansKr(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 본문
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.description_outlined,
                            size: 18, color: AppTheme.subtleText),
                          const SizedBox(width: 8),
                          Text('상세 정보',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.subtleText,
                            )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(desc, style: GoogleFonts.notoSansKr(fontSize: 15)),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                            size: 18, color: AppTheme.subtleText),
                          const SizedBox(width: 8),
                          Text(
                            '${report.latitude.toStringAsFixed(4)}, ${report.longitude.toStringAsFixed(4)}',
                            style: GoogleFonts.notoSansKr(
                              fontSize: 12,
                              color: AppTheme.subtleText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              FilledButton(
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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delivery_dining, size: 24),
            const SizedBox(width: 8),
            const Text('배달 지도'),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      size: 56,
                      color: AppTheme.dangerColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '지도를 불러올 수 없어요',
                    style: GoogleFonts.notoSansKr(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '네이버 클라우드 플랫폼에서\n클라이언트 ID를 확인해 주세요.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansKr(
                      fontSize: 14,
                      color: AppTheme.subtleText,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
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