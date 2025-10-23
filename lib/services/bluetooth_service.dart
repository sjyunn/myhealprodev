// lib/services/bluetooth_service.dart (전체 교체)

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';

// BluetoothService 클래스: flutter_reactive_ble API 기반으로 재작성
class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  final FlutterReactiveBle _ble = FlutterReactiveBle();
  final String targetDeviceName = "HealingFitPro Control";

  // rxdart를 사용하여 현재 연결 상태를 불리언으로 관리
  final _connectionState = BehaviorSubject<bool>.seeded(false);
  Stream<bool> get isConnectedStream => _connectionState.stream;
  bool get isConnected => _connectionState.value;

  // 현재 연결된 디바이스 ID
  String? _connectedDeviceId;
  StreamSubscription? _scanSubscription;

  // 현재 연결 스트림 구독을 관리할 변수
  StreamSubscription<ConnectionStateUpdate>? _connectionStateSubscription;

  // 1. 장치 스캔 및 연결 로직
  Future<void> scanAndConnect() async {
    if (isConnected) return;

    print('Reactive BLE 스캔 시작...');
    _connectionState.add(false);

    // withServices는 반드시 List<Uuid> 타입을 받습니다.
    // UUID 필터링 없이 일단 모든 장치 스캔을 시도합니다.
    _scanSubscription = _ble.scanForDevices(
      withServices: [], // 필터링 없이 스캔
      scanMode: ScanMode.lowLatency,
    ).listen((device) async {
      print('[SCAN RESULT] Device Found: ${device.name}, ID: ${device.id}');

      if (device.name == targetDeviceName) {
        // 목표 장치 발견 시 스캔 중단
        _scanSubscription?.cancel();
        _connectedDeviceId = device.id;

        await _connectDevice(device.id);
        return;
      }
    }, onError: (e) {
      print("BLE 스캔 오류 발생: $e");
    });

    // 타임아웃 처리
    await Future.delayed(const Duration(seconds: 10));
    _scanSubscription?.cancel();

    if (!_connectionState.value) {
      print('10초 동안 장치를 찾지 못했습니다.');
    }
  }

  // 2. 장치 연결 및 상태 관리
  // 5. 헬퍼 함수: 장치 연결 로직 분리 및 스트림 구독 저장
  Future<void> _connectDevice(String deviceId) async {
    print('장치 연결 시도: $deviceId');

    try {
      // ⬇️ 스트림 구독 객체를 _connectionStateSubscription 변수에 할당하고,
      //    onError 콜백을 listen 함수 내부의 인수로 전달하여 문법 오류를 해결합니다. ⬇️
      _connectionStateSubscription = _ble.connectToDevice(id: deviceId).listen(
              (connectionState) {
            if (connectionState.connectionState == DeviceConnectionState.connected) {
              print("장치 연결 성공!");
              _connectionState.add(true);
              // TODO: Characteristic Discovery 로직 추가
            } else if (connectionState.connectionState == DeviceConnectionState.disconnected) {
              print("장치 연결 해제됨.");
              _connectionState.add(false);
              _connectedDeviceId = null;
            }
          },
          // onError 콜백을 listen 함수의 명시적 파라미터로 전달합니다.
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

  // 3. 연결 해제
  // 6. 연결 해제 (스트림 취소를 통한 안전한 해제)
  Future<void> disconnect() async {
    // 연결 스트림을 취소하여 연결을 해제합니다.
    if (_connectionStateSubscription != null) {
      try {
        await _connectionStateSubscription!.cancel(); // ⬅️ 연결 해제 (오류 해결)
        print("장치 연결 해제됨 (스트림 취소).");
      } catch (e) {
        print("연결 해제 오류: $e");
      }
    }

    _connectionState.add(false);
    _connectedDeviceId = null;
  }
}