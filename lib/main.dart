// lib/main.dart

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // ← 추가
import 'package:permission_handler/permission_handler.dart';

import 'pages/main_shell.dart';
import 'pages/connection_page.dart';
import 'pages/controller_page.dart';
import 'services/bluetooth_service.dart';
import 'utils/database_manager.dart';

Future<void> main() async {
  // Flutter 엔진 바인딩 초기화 (main이 async일 때 필수)
  WidgetsFlutterBinding.ensureInitialized();
  await requestNearbyDevicesPermission(); // ◀️ 권한 요청 함수 호출

  // ⬇️ 한국어 로케일 초기화 ⬇️
  await initializeDateFormatting('ko_KR', null);

  // ⬇️ Hive 데이터베이스 초기화 ⬇️
  await DatabaseManager.initialize();

  runApp(const HeadsetControlApp());
}

Future<void> requestNearbyDevicesPermission() async {
  // Android 12+ 에서 필요한 새로운 권한들
  final statusScan = await Permission.bluetoothScan.request();
  final statusConnect = await Permission.bluetoothConnect.request();

  // Android 11 이하 및 BLE 스캔의 전통적인 요구 사항
  final statusLocation = await Permission.locationWhenInUse.request();

  if (statusScan.isGranted && statusConnect.isGranted && statusLocation.isGranted) {
    print("모든 근처 기기 권한이 허용되었습니다.");
  } else {
    // 권한 중 하나라도 거부되었다면, 사용자에게 다음 실행 시 다시 요청하거나 설정으로 유도할 수 있습니다.
    print("근처 기기 권한 중 일부가 거부되었습니다.");
  }
}

class HeadsetControlApp extends StatefulWidget {
  const HeadsetControlApp({super.key});

  @override
  State<HeadsetControlApp> createState() => _HeadsetControlAppState();
}

// lib/main.dart 내 _HeadsetControlAppState 클래스

class _HeadsetControlAppState extends State<HeadsetControlApp> {
  // ⚠️ Health Connect SDK와의 충돌을 피하기 위해 static으로 선언하지 않습니다.
  // 이 인스턴스는 ConnectionPage 및 ControllerPage에서 사용될 것입니다.
  // final BluetoothService _bluetoothService = BluetoothService();

  @override
  void initState() {
    super.initState();
    // ⚠️ Navigator 충돌 방지를 위해, 모든 스트림 리스너는 ConnectionPage나 ControllerPage로 이동했습니다.
  }

  @override
  Widget build(BuildContext context) {
    // ⬇️ 수정: StreamBuilder를 제거하고 MaterialApp만 반환하여 라우팅 안정성을 확보합니다. ⬇️
    return MaterialApp(
      title: 'Bluetooth Headset Controller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34d399)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        // 앱의 시작점
        '/': (context) => const ConnectionPage(),
        // 연결 성공 시 MainShell로 이동하여 하단 메뉴를 표시
        '/controller': (context) => const MainShell(),
      },
    );
    // ⬆️ 수정 완료 ⬆️
  }
}