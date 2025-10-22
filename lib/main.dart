// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;

import 'pages/connection_page.dart';
import 'pages/controller_page.dart';
import 'services/bluetooth_service.dart';

void main() {
  runApp(const HeadsetControlApp());
}

class HeadsetControlApp extends StatefulWidget {
  const HeadsetControlApp({super.key});

  @override
  State<HeadsetControlApp> createState() => _HeadsetControlAppState();
}

class _HeadsetControlAppState extends State<HeadsetControlApp> {
  final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    // 앱 전체에서 블루투스 연결 상태를 감지하여 화면을 전환하도록 리스너 설정
    _bluetoothService.connectionStateStream.listen((state) {
      if (state == fb.BluetoothConnectionState.connected) {
        // 연결 성공 시 ControllerPage로 이동
        Navigator.of(context).pushReplacementNamed('/controller');
      }
      // 연결 해제 시 ConnectionPage로 돌아가도록 할 수도 있으나, 여기서는 일단 ControllerPage에 멈춥니다.
      // ConnectionPage에서 연결 실패 시 재시도 로직을 담당합니다.
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bluetooth Headset Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34d399)),
        useMaterial3: true,
      ),
      // 초기 화면을 ConnectionPage로 설정
      initialRoute: '/',
      routes: {
        '/': (context) => const ConnectionPage(), // 시작 화면
        '/controller': (context) => const ControllerPage(), // 컨트롤러 화면
      },
    );
  }
}
