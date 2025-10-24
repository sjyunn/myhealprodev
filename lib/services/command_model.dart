// lib/services/command_model.dart

import 'dart:typed_data';

// 1. APP 명령 코드 정의 (Write)
enum TesCommandType {
  setModeHealing, // 0x01
  setModeStudy,   // 0x02
  setModeSleep,   // 0x03
  tensStart,      // 0x04
  tensStop,       // 0x05
  setTensTime,    // 0x0B (TENS시간 설정)
  setVolume,      // 0x0C (이어폰 음량 설정)
  // ... (다른 커맨드도 필요 시 추가)
}

// 2. 명령어 데이터 구조체
class TesCommand {
  final TesCommandType type;
  final int? value; // TENS 세기, 시간, 볼륨 등에 사용되는 값

  // CRC8 체크섬은 현재 구현에서 생략하고, 디바이스가 요구하는 최종 바이트 형식만 맞춥니다.
  // 실제 프로토콜 구현 시 이 부분에 CRC8 계산 로직이 추가되어야 합니다.

  TesCommand({required this.type, this.value});

  // 3. 커맨드를 디바이스가 요구하는 바이트 배열 (List<int>)로 변환
  List<int> toBytes() {
    // 모든 커맨드는 55 AA 00 0X 00 01 XX YY(CRC8) 형태를 따릅니다.
    final List<int> header = [0x55, 0xAA, 0x00];
    final List<int> payload = [0x00, 0x01]; // Reserve + length

    int commandCode;
    List<int> data = [];

    switch (type) {
      case TesCommandType.setModeHealing:
        commandCode = 0x01; // 힐링모드 CMD
        data = [0x00, 0x01]; // 모드값 0x01
        break;
      case TesCommandType.setModeStudy:
        commandCode = 0x02; // 학습모드 CMD
        data = [0x00, 0x02]; // 모드값 0x02
        break;
      case TesCommandType.setModeSleep:
        commandCode = 0x03; // 수면모드 CMD
        data = [0x00, 0x03]; // 모드값 0x03
        break;
      case TesCommandType.tensStart:
        commandCode = 0x04; // TENS 시작 CMD
        data = [0x00, 0x04]; // 시작값 0x04
        break;
      case TesCommandType.tensStop:
        commandCode = 0x05; // TENS 정지 CMD
        data = [0x00, 0x05]; // 정지값 0x05
        break;
      case TesCommandType.setTensTime:
      case TesCommandType.setVolume:
      // TENS 시간 또는 볼륨 설정 (CMD-0x0B 또는 0x0C)
        commandCode = type == TesCommandType.setTensTime ? 0x0B : 0x0C;
        // 값(Value)은 UINT8 (1바이트)로 가정합니다.
        data = [value ?? 0x00, 0x00]; // XX YY 형태에 맞춰 2바이트 전송
        break;
      default:
        return [];
    }

    final commandBytes = <int>[
      ...header,
      commandCode,
      ...payload,
      ...data,
      0x00 // 임시 CRC8 (실제 CRC 계산 로직 필요)
    ];

    return commandBytes;
  }
}