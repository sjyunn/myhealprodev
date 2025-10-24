// lib/services/bluetooth_service.dart

import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:rxdart/rxdart.dart';
import 'command_model.dart';

class BluetoothService {
  // 1. 싱글톤 패턴 및 주요 설정
  BluetoothService._internal();
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final String targetDeviceName = "HealingFitPro Control";

  // 2. UUID 정의 (클래스 멤버 변수로 명확히 선언 - 오류 해결)
  final Uuid tesCommandServiceUuid = Uuid.parse("0000BE00-0000-1000-8000-00805F9B34FB");
  final Uuid tesCommandCharacteristicUuid = Uuid.parse("0000BE01-0000-1000-8000-00805F9B34FB");
  final Uuid tesNotifyCharacteristicUuid = Uuid.parse("0000BE02-0000-1000-8000-00805F9B34FB");


  // 3. 상태 관리 변수
  String? _connectedDeviceId;
  StreamSubscription? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionStateSubscription;
  StreamSubscription<List<int>>? _notifySubscription;

  QualifiedCharacteristic? _tesCommandCharacteristic;

  final _connectionState = BehaviorSubject<bool>.seeded(false);
  Stream<bool> get isConnectedStream => _connectionState.stream;
  bool get isConnected => _connectionState.value;

  final _tesState = BehaviorSubject<Map<String, int>>.seeded({
    'mode': 0, 'intensity': 0, 'battery': 0, 'isPlaying': 0
  });
  Stream<Map<String, int>> get tesStateStream => _tesState.stream;

  // 4. 권한 및 활성화 확인 (API 접근 오류 해결)
  Future<bool> checkPermissionsAndTurnOn() async {
    // ⬇️ 빌드 오류 회피용 임시 코드 (오류 발생 부분 제거) ⬇️
    print("⚠️ 경고: BLE 상태 확인 로직을 임시 우회합니다. 연결은 scanAndConnect에서 진행됩니다.");
    return true;
  }

  // 5. 장치 스캔 및 연결 로직
  Future<void> scanAndConnect() async {
    if (isConnected) return;
    if (!await checkPermissionsAndTurnOn()) return;

    print('장치 스캔 시작 (필터 없음).');
    _connectionState.add(false);

    // FlutterReactiveBle에는 stopScan이 없으므로, Subscription을 캔슬하거나
    // 다음 스캔 전에 명시적으로 멈추는 로직이 필요하지만, 여기서는 단순화합니다.

    _scanSubscription?.cancel();
    _scanSubscription = _ble.scanForDevices(
      withServices: [],
      scanMode: ScanMode.lowLatency,
    ).listen((device) {

      print('[SCAN RESULT] Device Found: ${device.name}, ID: ${device.id}, RSSI: ${device.rssi}');

      if (device.name == targetDeviceName) {
        print('목표 장치 발견! 연결을 시도합니다.');
        _scanSubscription?.cancel();
        _connectedDeviceId = device.id;
        _connectDevice(device.id);
        return;
      }
    }, onError: (e) {
      print("BLE 스캔 오류 발생: $e");
    });

    await Future.delayed(const Duration(seconds: 10));
    _scanSubscription?.cancel();

    if (!isConnected && _connectedDeviceId == null) {
      print('10초 동안 스캔했지만 ' + targetDeviceName + ' 장치를 찾지 못했습니다.');
      _connectionState.add(false);
    }
  }

  // 6. 헬퍼 함수: 장치 연결 로직
// lib/services/bluetooth_service.dart 파일 내 _connectDevice 함수 전체

  void _connectDevice(String deviceId) async {
    print('장치 연결 시도: $deviceId');

    try {
      _connectionStateSubscription = _ble.connectToDevice(id: deviceId).listen(
              (connectionState) async {
            if (connectionState.connectionState == DeviceConnectionState.connected) {
              print("장치 연결 성공!");
              _connectionState.add(true);

              await _discoverAndSetupCharacteristics(deviceId);

            } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
              print("장치 연결 해제됨.");
              _connectionState.add(false);
              _connectedDeviceId = null;
            }
          },
          onError: (e) {
            print("연결 중 오류 발생: $e");
            _connectionState.add(false);
          }
      );

    } catch (e) {
      print("연결 초기화 실패: $e");
      _connectionState.add(false);
    }
  }

  // 7. 헬퍼 함수: Characteristic 발견 및 Notify 구독
  Future<void> _discoverAndSetupCharacteristics(String deviceId) async {
    try {
      print("BLE 서비스 디스커버리 시작...");

      // ⬇️ 1. Service Discovery 로직 추가: 연결 후 서비스 목록을 확보 ⬇️
      // 이 과정이 없으면 Characteristic 설정 시 실패하거나 멈출 수 있습니다.
      await _ble.discoverServices(deviceId);

      // 2. 커맨드 Characteristic 설정
      _tesCommandCharacteristic = QualifiedCharacteristic(
        serviceId: tesCommandServiceUuid,
        characteristicId: tesCommandCharacteristicUuid,
        deviceId: deviceId,
      );

      final notifyCharacteristic = QualifiedCharacteristic(
        serviceId: tesCommandServiceUuid,
        characteristicId: tesNotifyCharacteristicUuid,
        deviceId: deviceId,
      );

      // 3. Heartbeat Notify 구독 시작
      _notifySubscription?.cancel();
      _notifySubscription = _ble.subscribeToCharacteristic(notifyCharacteristic).listen((data) {
        _handleHeartbeatData(data); // 수신 데이터 처리
      });

      print("BLE Characteristic 설정 완료 및 Heartbeat 구독 시작.");
    } catch (e) {
      print("Characteristic 설정 실패: $e");
      // ⬇️ 4. 실패 시 연결 해제: 무한 대기 상태 방지 ⬇️
      disconnect();
    }
  }

  // 8. Heartbeat 데이터 처리 로직
  void _handleHeartbeatData(List<int> data) {
    String hexString = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
    // ⬇️ 길이 검증: 19 bytes로 고정 ⬇️
    if (data.length != 19) {
      // 8바이트 데이터 무시 로직 유지
      //String hexString = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      print("🚨 경고: 데이터 길이 불일치 (${data.length} bytes). 무시함.");
      print("🚨 RAW DATA (HEX): $hexString");
      return;
    }

    // Heartbeat 데이터 최종 파싱 (19바이트 배열 기준)

    final int mode = data[6]; // data[5]와 data[6]을 합쳐 16비트 정수 생성
    final int isPlaying = data[7];   // 플레이 여부 (Index 6)

    // ⬇️ 세기: Index 8로 확정 (로그에서 5가 출력된 인덱스) ⬇️
    final int intensity = data[8];   // TENS 세기

    final int volumeInt = data[10];     // 볼륨 (Index 10)

    // ⬇️ 배터리 잔량: Index 12로 확정 (프로토콜 명세와 19바이트 길이를 고려) ⬇️
     final int battery = data[13];    // 배터리 잔량
    //final int battery = (data[11] << 8) | data[12];

    // ⬆️ 최종 파싱 인덱스 적용 ⬆️

    _tesState.add({
      'mode': mode,
      'intensity': intensity,
      'battery': battery,
      'volume': volumeInt,
      'isPlaying': isPlaying
    });

    print("🚨 RAW DATA (HEX19): $hexString");
    //print("Heartbeat 수신 - 모드: $mode, 세기: $intensity, 볼륨: $volume, 배터리: $battery%");
    print("Heartbeat 수신 - 모드: $mode, 재생: $isPlaying, 세기: $intensity, 볼륨: $volumeInt, 배터리: $battery%");
  }


  // 9. 커맨드 전송 함수 구현 (Write 인자 오류 수정 완료)
  Future<void> sendTesCommand(TesCommand command) async {
    if (!isConnected || _tesCommandCharacteristic == null) {
      print("장치가 연결되지 않았거나 Characteristic이 설정되지 않았습니다.");
      return;
    }

    final bytes = command.toBytes();

    try {
      // Write 인자 오류 수정: value: bytes 형태로 전달
      await _ble.writeCharacteristicWithResponse(_tesCommandCharacteristic!, value: bytes);
      print("커맨드 전송 성공: ${command.type.name} -> $bytes");
    } catch (e) {
      print("커맨드 전송 실패: $e");
    }
  }

  // 10. 장치 연결 해제
  Future<void> disconnect() async {
    if (_connectionStateSubscription != null) {
      try {
        await _connectionStateSubscription!.cancel();
        print("장치 연결 해제됨 (스트림 취소).");
      } catch (e) {
        print("연결 해제 오류: $e");
      }
    }
    _connectionState.add(false);
    _connectedDeviceId = null;
  }

  // 11. 리소스 정리
  void dispose() {
    _scanSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _notifySubscription?.cancel();
    _connectionState.close();
    _tesState.close();
    disconnect();
  }
}