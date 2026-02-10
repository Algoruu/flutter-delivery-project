// 모바일/데스크탑에서 웹용 위젯을 대체하는 스텁
import 'package:flutter/material.dart';

class WebNaverMap extends StatelessWidget {
  final String clientId;
  const WebNaverMap({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('웹 환경이 아닙니다.'));
  }
}
