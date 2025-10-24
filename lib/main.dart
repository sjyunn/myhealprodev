// lib/main.dart

import 'package:flutter/material.dart';
//import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;

import 'pages/main_shell.dart';
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

  }

  @override
  Widget build(BuildContext context) {
    // ⬇️ StreamBuilder를 사용하여 연결 상태에 따라 화면을 전환합니다. ⬇️
    return StreamBuilder<bool>(
      stream: _bluetoothService.isConnectedStream,
      initialData: false, // 초기 데이터는 연결 안 됨(false)
      builder: (context, snapshot) {
        final bool isConnected = snapshot.data ?? false;

        // 앱이 처음 로드될 때 또는 연결이 끊겼을 때는 ConnectionPage를 보여줍니다.
        // 연결이 성공했을 때는 (ConnectionPage에서) ControllerPage로 직접 이동합니다.

        return MaterialApp(
          title: 'Bluetooth Headset Controller',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF34d399)),
            useMaterial3: true,
          ),
          // ⚠️ isConnected 상태를 routes에 전달하지 않고,
          // ConnectionPage와 ControllerPage에서 BluetoothService를 직접 사용하도록 합니다.
          initialRoute: '/',
          routes: {
            '/': (context) => const ConnectionPage(),
            '/controller': (context) => const MainShell(), // ◀️ 이 부분이 MainShell이어야 합니다.
          },

          // Navigator 충돌을 피하고, 연결 성공 시 자동으로 ControllerPage로 이동합니다.
          // ConnectionPage에서 연결이 성공하면 Navigator.of(context).pushReplacementNamed('/controller')를 호출해야 합니다.

          // ⚠️ Note: ConnectionPage에서 Navigator 호출이 이미 PostFrameCallback으로 수정되었으므로,
          // initState의 복잡한 리스너를 제거하는 것만으로 충돌은 해결될 것입니다.

          // 최종적으로, Navigator를 포함하는 MaterialApp의 컨텍스트를 사용하도록 보장합니다.
        );
      },
    );
  }
}
