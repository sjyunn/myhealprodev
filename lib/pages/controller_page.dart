// lib/pages/controller_page.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
//import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;

import '../widgets/tes_control.dart';
import '../services/bluetooth_service.dart';
import '../types.dart'; // 정의한 Mode enum 사용

class ControllerPage extends StatefulWidget {
  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  // ------------------------------------
  // 블루투스 서비스 및 상태 변수
  final BluetoothService _bluetoothService = BluetoothService();

  bool isConnected = false;
  Mode activeMode = Mode.healing;
  bool isPlaying = true;
  double tesLevel = 10.0;
  double volume = 40.0;
  final int batteryLevel = 92;

  final Color mainColor = const Color(0xFF34d399); // Tailwind emerald-500

  final modes = const [
    {'id': Mode.study, 'name': '학습모드', 'icon': Icons.edit_note_rounded},
    {'id': Mode.healing, 'name': '힐링모드', 'icon': Icons.favorite_rounded},
    {'id': Mode.sleep, 'name': '수면모드', 'icon': Icons.nights_stay_rounded},
  ];
  // ------------------------------------

  @override
  void initState() {
    super.initState();

    // 블루투스 연결 상태 변화를 구독하여 UI 상태를 업데이트
    _bluetoothService.isConnectedStream.listen((state) {
      if(mounted) {
        setState(() {
          isConnected = state;
        });
      }
    });

    // 이 페이지는 ConnectionPage에서 넘어올 때만 연결 시도를 합니다.
    // 이 페이지에 들어왔다면 연결 상태는 이미 ConnectionPage에 의해 결정되었거나,
    // 사용자가 '넘어가기'를 눌러 비활성화 상태로 진입한 것입니다.
    // 이 페이지 진입 시 scanAndConnect()는 호출하지 않습니다. (ConnectionPage가 담당)
  }

  // ----------------------------------------------------
  // 1. Header (상단) 위젯
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              text: 'HEALINGFIT',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.grey[600], letterSpacing: 1.5),
              children: <TextSpan>[
                TextSpan(text: 'PRO', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey[700])),
              ],
            ),
          ),

          // 블루투스 연결/해제 버튼
          GestureDetector(
            onTap: () {
              // 연결 상태에 따라 연결/해제 로직 호출
              if (isConnected) {
                _bluetoothService.disconnect();
              } else {
                // 연결이 끊겼다면 ConnectionPage로 돌아가 연결 재시도
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isConnected ? mainColor.withOpacity(0.8) : Colors.grey[300],
                border: Border.all(
                  color: isConnected ? mainColor.withOpacity(0.4) : Colors.transparent,
                  width: 4.0,
                ),
              ),
              child: Icon(
                FontAwesomeIcons.bluetoothB,
                size: 24,
                color: isConnected ? Colors.white : Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. Mode Selector 위젯 함수
  Widget _buildModeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: modes.map((mode) {
        final isActive = activeMode == mode['id'];
        return Column(
          children: [
            GestureDetector(
              onTap: () {
                setState(() => activeMode = mode['id'] as Mode);
              },
              child: Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? mainColor : Colors.grey[200],
                  boxShadow: isActive ? [BoxShadow(color: mainColor.withOpacity(0.4), blurRadius: 10)] : null,
                ),
                child: Icon(
                  mode['icon'] as IconData,
                  size: 30,
                  color: isActive ? Colors.white : Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              mode['name'] as String,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? mainColor : Colors.grey[400],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // 3. Main Player (중앙 컨트롤) 위젯
  Widget _buildPlayerControl() {
    return Center(
      child: Container(
        width: 150,
        height: 150,
        margin: const EdgeInsets.symmetric(vertical: 20),
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: mainColor, width: 4),
          ),
          child: InkWell(
            onTap: () {
              setState(() => isPlaying = !isPlaying);
            },
            customBorder: const CircleBorder(),
            child: Center(
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 40,
                color: mainColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 4. TES 및 Volume Control (하단) 위젯
  Widget _buildControls() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // TES Intensity (제목 및 배터리)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.flash_on_rounded, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text('TES 세기', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              Row(
                children: [
                  Text('${batteryLevel}%', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[600])),
                  const SizedBox(width: 8),
                  Icon(FontAwesomeIcons.batteryFull, size: 24, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),

        // TES Control: 수평 슬라이더 사용
        TesControl(
          value: tesLevel,
          onChange: (newVal) => setState(() => tesLevel = newVal),
        ),

        const SizedBox(height: 20),

        // Volume Control
        Row(
          children: [
            Icon(Icons.volume_up_rounded, size: 24, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 8.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                  activeTrackColor: mainColor,
                  inactiveTrackColor: Colors.grey[200],
                  thumbColor: Colors.white,
                ),
                child: Slider(
                  min: 0,
                  max: 100,
                  value: volume,
                  onChanged: (newVal) => setState(() => volume = newVal),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ----------------------------------------------------
  // Main Build 함수: 비활성화 로직 통합
  @override
  Widget build(BuildContext context) {
    // isConnected 상태가 false일 때 컨트롤을 비활성화합니다.
    bool shouldDisableControls = !isConnected;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. 모든 컨트롤을 IgnorePointer로 감싸 비활성화합니다.
            IgnorePointer(
              ignoring: shouldDisableControls, // isConnected이 false면 true
              child: Opacity(
                opacity: shouldDisableControls ? 0.3 : 1.0, // 비활성화 시 투명도 조절
                child: SingleChildScrollView( // 오버플로우 방지
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),

                        // Main Content
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Greeting
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ⚠️ Greeting 텍스트는 isConnected 여부와 관계없이 표시되도록 합니다.
                                  const Text('힐링핏과 함께', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                                  Text.rich(
                                    TextSpan(
                                      text: '오늘도 ',
                                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                                      children: [TextSpan(text: '파이팅!', style: TextStyle(color: mainColor))],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                ],
                              ),

                              // Mode Selector
                              _buildModeSelector(),

                              // Player Control
                              _buildPlayerControl(),

                              // TES Intensity and Volume Control
                              _buildControls(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20), // 하단 여백
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. 비활성화 상태일 때 오버레이 메시지 표시 (첨부 2번 이미지 상단 메시지 구현)
            if (shouldDisableControls)
              Positioned(
                top: 80, // 상단 Header 아래에 위치하도록 조정
                left: 20,
                child: Text.rich(
                  TextSpan(
                    text: '힐링핏과\n',
                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
                    children: [
                      TextSpan(
                        text: '블루투스 연결이 필요해요!',
                        style: TextStyle(color: mainColor),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}