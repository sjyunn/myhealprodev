// lib/pages/controller_page.dart

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
//import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fb;

import '../widgets/tes_control.dart';
import '../services/bluetooth_service.dart';
import '../types.dart'; // 정의한 Mode enum 사용
import 'dart:async';

import '../services/command_model.dart';

class ControllerPage extends StatefulWidget {
  const ControllerPage({super.key});

  @override
  State<ControllerPage> createState() => _ControllerPageState();
}

class _ControllerPageState extends State<ControllerPage> {
  // ------------------------------------
  // 블루투스 서비스 및 상태 변수
  final BluetoothService _bluetoothService = BluetoothService();

  StreamSubscription<Map<String, int>>? _tesStateSubscription;

  bool isConnected = false;
  Mode activeMode = Mode.healing;
  bool isPlaying = true;
  double tesLevel = 0.0;
  double volume = 7.0;
  int batteryLevel = 92;

  final Color mainColor = const Color(0xFF34d399); // Tailwind emerald-500

  final modes = const [
    {'id': Mode.study, 'name': '학습모드', 'icon': Icons.edit_note_rounded},
    {'id': Mode.healing, 'name': '힐링모드', 'icon': Icons.favorite_rounded},
    {'id': Mode.sleep, 'name': '수면모드', 'icon': Icons.nights_stay_rounded},
  ];
  // ------------------------------------

  @override
  @override
  void initState() {
    super.initState();

    // 1. BLE 연결 상태 구독 (Bool 값)
    // ⬇️ isConnectedStream을 구독하고 isConnected 상태를 업데이트합니다. ⬇️
    _bluetoothService.isConnectedStream.listen((isConnectedStatus) { // ◀️ 변수명을 명확히 함
      if (mounted) {
        setState(() {
          isConnected = isConnectedStatus; // ◀️ 상태를 올바른 변수(isConnectedStatus)로 업데이트
        });
      }
    });

    // 2. Heartbeat 데이터 상태 구독 (Map 값)
    // ⬇️ Heartbeat 데이터를 받아와 UI 상태 변수들을 업데이트합니다. ⬇️
    _tesStateSubscription = _bluetoothService.tesStateStream.listen((tesState) {
      if (mounted) {
        setState(() {
          // Heartbeat 데이터로 UI 상태 변수 갱신
          tesLevel = tesState['intensity']?.toDouble() ?? tesLevel;
          batteryLevel = tesState['battery'] ?? batteryLevel; // ◀️ 올바른 변수 사용
          final int isPlayingInt = tesState['isPlaying'] ?? 0;
          isPlaying = isPlayingInt == 1; // ◀️ isPlaying 멤버 변수 업데이트 (0=false, 1=true)

          // 1. Map에서 값을 가져옵니다. (Map<String, int> 타입이므로 as int? 필요 없음)
          final int? receivedVolume = tesState['volume'];
          // print('🔍 DEBUG: Heartbeat Stream 수신됨.');
          // print('🔍 DEBUG: receivedVolume Value: $receivedVolume');
          // print('🔍 DEBUG: receivedVolume Type: ${receivedVolume.runtimeType}');

          // 2. 받은 값이 null이 아닐 때만 업데이트합니다.
          if (receivedVolume != null) {
            // 2. double 변환 후 할당 (double 타입으로 통일)
            volume = receivedVolume.toDouble().clamp(0.0, 15.0);
            // print('🔍 DEBUG: UI Volume Updated to: $volume');
          } else {
            // print('🔍 DEBUG: receivedVolume is NULL. UI not updated.');
          }

          final int modeInt = tesState['mode'] ?? 0; // ◀️ 변수 정의
          // 로그에서 확인된 매핑 (1: 학습, 2: 수면, 3: 힐링)에 따라 activeMode 설정
          if (modeInt == 3) {
            activeMode = Mode.healing;
          } else if (modeInt == 2) {
            activeMode = Mode.sleep;
          } else if (modeInt == 1) {
            activeMode = Mode.study;
          }
        });
      }
    });
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
                final newMode = mode['id'] as Mode;
                setState(() => activeMode = newMode);

                // ⬇️ 모드 변경 커맨드 전송 ⬇️
                TesCommandType commandType;
                if (newMode == Mode.healing) {
                  commandType = TesCommandType.setModeHealing; // CMD-0x01
                } else if (newMode == Mode.study) {
                  commandType = TesCommandType.setModeStudy;   // CMD-0x02
                } else { // Mode.sleep
                  commandType = TesCommandType.setModeSleep;    // CMD-0x03
                }

                _bluetoothService.sendTesCommand(
                    TesCommand(type: commandType)
                );
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
              // 1. 현재 isPlaying 상태를 확인하여 반대 명령을 결정합니다.
              final commandType = isPlaying ? TesCommandType.tensStop : TesCommandType.tensStart;

              // ⬇️ 수정: Write 명령 전송 로직 추가 ⬇️
              _bluetoothService.sendTesCommand(
                  TesCommand(type: commandType) // CMD-0x04 또는 CMD-0x05 전송
              );

              // 2. ⚠️ setState(() => isPlaying = !isPlaying); 이 줄은 삭제합니다.
              // Heartbeat 데이터 수신을 통해 디바이스 상태와 동기화되므로,
              // 앱에서 자체적으로 상태를 변경하면 안 됩니다.
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
          onChange: (newVal) {
            setState(() => tesLevel = newVal);

            // ⬇️ TENS 세기 변경 커맨드 전송 ⬇️
            _bluetoothService.sendTesCommand(
              TesCommand(
                // CMD-0x0C (이어폰 음량 설정)으로 세기를 조절한다는 가정 하에 전송합니다.
                // 실제 프로토콜에 따라 정확한 CMD (예: CMD-0x09)로 변경해야 합니다.
                type: TesCommandType.setVolume,
                value: newVal.round(),
              ),
            );
          },
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
                  max: 15.0, // ◀️ double 값 명시 (Flutter Slider 요구 사항)
                  value: volume, // ◀️ 수정: volume 변수가 double이므로, toDouble() 제거
                  onChanged: (newVal) {
                    // 1. 앱 UI 상태 업데이트: double 값을 그대로 저장 (동기화 Read 로직과 일치)
                    setState(() => volume = newVal); // ◀️ 수정: round() 제거

                    // 2. 볼륨 변경 커맨드 전송 (Write): 디바이스는 정수(0-15)를 받으므로 round() 사용
                    _bluetoothService.sendTesCommand(
                      TesCommand(
                        type: TesCommandType.setVolume, // CMD-0x0C
                        value: newVal.round(), // ◀️ 전송 시에만 정수로 변환하여 디바이스에 Write
                      ),
                    );
                  },
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