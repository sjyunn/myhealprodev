// lib/services/bluetooth_service.dart

import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothService {
  // 1. 싱글톤 패턴
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  // 2. 목표 디바이스 이름 설정 (첨부 이미지 기반)
  final String targetDeviceName = "Mobifren HealingFitPro";

  // 3. 상태 관리 변수
  BluetoothDevice? connectedDevice;

  // 현재 장치가 연결 상태인지 즉시 알려주는 getter
  bool get isConnected {
    // connectedDevice가 null이 아니고, 마지막 연결 상태가 connected일 때 true 반환
    return connectedDevice?.connectionState.last == BluetoothConnectionState.connected;
  }

  StreamSubscription<List<ScanResult>>? _scanSubscription;

  // 4. 연결 상태를 UI에 전달하는 StreamController
  final _connectionStateController = StreamController<BluetoothConnectionState>.broadcast()
    ..add(BluetoothConnectionState.disconnected);

  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;

  // 1. 블루투스 권한 확인 및 활성화 요청
  Future<bool> checkPermissionsAndTurnOn() async {
    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      await FlutterBluePlus.turnOn();
    }

    final finalAdapterState = await FlutterBluePlus.adapterState.first;
    if (finalAdapterState != BluetoothAdapterState.on) {
      print("블루투스 활성화 실패.");
      _connectionStateController.add(BluetoothConnectionState.disconnected);
    }
    return finalAdapterState == BluetoothAdapterState.on;
  }


  // 5. 장치 스캔 및 연결 로직 (최신 API 반영 및 문법 오류 수정)
  Future<void> scanAndConnect() async {
    if (connectedDevice != null && connectedDevice!.connectionState.last == BluetoothConnectionState.connected) {
      print("장치가 이미 연결되어 있습니다.");
      return;
    }

    if (!await checkPermissionsAndTurnOn()) {
      print("블루투스 비활성화 상태입니다. 연결을 진행할 수 없습니다.");
      return;
    }

    // ⬇️ 문법 오류 수정: 문자열 결합 방식으로 안전하게 출력 ⬇️
    print('장치 스캔 시작. 목표 이름 필터: ' + targetDeviceName);

    await FlutterBluePlus.stopScan();

    BluetoothDevice? foundDevice;

    // 1. 스캔 결과 구독 시작: 목표 장치를 찾으면 스캔을 멈춥니다.
    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      for (final scanResult in results) {
        if (scanResult.device.platformName == targetDeviceName) {
          foundDevice = scanResult.device;
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });

    // 2. 스캔 시작 (timeout 파라미터 사용)
    await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withNames: [targetDeviceName]
    );

    // 3. 스캔이 타임아웃 되거나 중지될 때까지 기다립니다.
    await FlutterBluePlus.isScanning.where((isScanning) => isScanning == false).first;

    // 구독 정리
    await _scanSubscription?.cancel();
    _scanSubscription = null;

    // 4. 장치가 발견되었는지 확인하고 연결을 시도합니다.
    if (foundDevice != null) {
      connectedDevice = foundDevice;

      // 연결 상태 변화를 UI에 전달하기 위해 구독 시작
      connectedDevice!.connectionState.listen((state) {
        _connectionStateController.add(state);
      });

      try {
        // ⬇️ 문법 오류 수정: 문자열 결합 방식으로 안전하게 출력 ⬇️
        print('장치 연결 시도: ' + targetDeviceName);
        await connectedDevice!.connect();
        print("장치 연결 성공!");
      } catch (e) {
        print("장치 연결 실패: $e");
        connectedDevice = null;
        _connectionStateController.add(BluetoothConnectionState.disconnected);
      }
    } else {
      // ⬇️ 문법 오류 수정: 문자열 결합 방식으로 안전하게 출력 ⬇️
      print('10초 동안 \'' + targetDeviceName + '\' 장치를 찾지 못했습니다.');
      _connectionStateController.add(BluetoothConnectionState.disconnected);
    }
  }

  // 6. 장치 연결 해제
  Future<void> disconnect() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
        print("장치 연결 해제됨.");
      } catch (e) {
        print("연결 해제 오류: $e");
      }
    }
    connectedDevice = null;
    _connectionStateController.add(BluetoothConnectionState.disconnected);
  }

  // 7. 리소스 정리 (앱 종료 시 호출)
  void dispose() {
    _scanSubscription?.cancel();
    _connectionStateController.close();
    disconnect();
  }
}