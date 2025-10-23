// lib/pages/connection_page.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/bluetooth_service.dart';
import 'dart:async'; // StreamSubscription을 위해 필요합니다.

class ConnectionPage extends StatefulWidget {
  const ConnectionPage({super.key});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  final BluetoothService _bluetoothService = BluetoothService();
  StreamSubscription<bool>? _connectionSubscription;
  bool _isConnecting = false;
  bool _isTimedOut = false; // 연결 시간 초과 상태

  @override
  void initState() {
    super.initState();

    // 1. 연결 상태 스트림 구독 시작
    _connectionSubscription = _bluetoothService.isConnectedStream.listen((isConnected) {
      // 연결이 성공했을 때만 실행
      if (isConnected) {
        // 2. Navigator가 준비된 후 안전하게 화면 전환 (핵심 수정 부분)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // 위젯이 여전히 트리에 존재하는지 확인
          if (mounted) {
            // ControllerPage로 이동하고 현재 페이지를 대체합니다.
            Navigator.of(context).pushReplacementNamed('/controller');
          }
        });
      }
    });

    // ⬇️⬇️⬇️ 이 부분이 가장 중요합니다. ⬇️⬇️⬇️
    // 2. 페이지가 로드되자마자 즉시 연결 시도 함수를 호출합니다.
    _startConnectionAttempt();
    // ⬆️⬆️⬆️ 이 줄을 추가해야 합니다. ⬆️⬆️⬆️
  }

  @override
  void dispose() {
    // 3. 위젯이 사라질 때 구독을 취소하여 메모리 누수 방지
    _connectionSubscription?.cancel();
    super.dispose();
  }


  // 연결 시도 로직
  void _startConnectionAttempt() async {
    if (mounted) {
      setState(() {
        _isConnecting = true;
        _isTimedOut = false;
      });
    }

    // 10초 스캔 및 연결 시도
    await _bluetoothService.scanAndConnect();

    // 연결 상태 확인 (ControllerPage로의 라우팅은 Main.dart에서 처리)
    if (mounted) {
      setState(() {
        _isConnecting = false;
        // 연결 성공 여부는 Main.dart의 Listener가 처리하며,
        // 여기서는 연결 시도가 끝났음을 표시
        if (!_bluetoothService.isConnected) {
          _isTimedOut = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text('기기 연결하기', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          // 우측 상단 '넘어가기' 버튼
          TextButton(
            onPressed: () {
              // TODO: ControllerPage로 넘어가기 (비활성화 상태로)
              Navigator.of(context).pushReplacementNamed('/controller', arguments: false);
            },
            child: Text('넘어가기', style: TextStyle(color: mainColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 상단 텍스트
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('힐링핏의 전원을 켜 주세요.', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                const Text('마이힐링핏 앱을 계속 이용하려면\n블루투스 연결이 필요해요.', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),

            // 중앙 아이콘 및 상태 메시지
            Column(
              children: [
                Container(
                  width: 150, height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnecting ? mainColor.withOpacity(0.1) : Colors.grey[200],
                    border: Border.all(color: mainColor.withOpacity(_isConnecting ? 0.3 : 0.0), width: 3),
                  ),
                  child: Center(
                    child: FaIcon(FontAwesomeIcons.bluetoothB, size: 70, color: mainColor.withOpacity(_isConnecting ? 1.0 : 0.5)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _isConnecting ? '연결 중...' : (_isTimedOut ? '연결 시간 초과' : '연결 준비 완료'),
                  style: TextStyle(color: _isTimedOut ? Colors.red : mainColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // 재시도 버튼 및 하단 메시지
            Column(
              children: [
                // 재시도 버튼
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isConnecting ? null : _startConnectionAttempt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('재시도', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
                ),
                if (_isTimedOut)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('연결 시간 초과', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}