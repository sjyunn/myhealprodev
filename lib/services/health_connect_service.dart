// lib/services/health_connect_service.dart

import 'package:health/health.dart';
import 'dart:async';
import 'package:intl/intl.dart'; // 날짜 포맷팅을 위해 추가
import '../models/daily_record.dart';
// DatabaseManager는 Hive DB와의 상호작용을 위해 필요합니다. (외부 정의 가정)
import '../utils/database_manager.dart';

class HealthConnectService {
  // 간단한 싱글톤 패턴 대신, 제공해주신 대로 Health 인스턴스를 사용합니다.
  // Health Connect SDK를 명시적으로 사용하도록 설정합니다.
  // final Health _health = Health(useHealthConnectIfAvailable: true);

  HealthConnectService._internal();
  static final HealthConnectService _instance = HealthConnectService._internal();
  factory HealthConnectService() => _instance;

  final Health _health = Health();

// 1. Health Connect API 사용 가능 여부 확인 및 권한 요청
  Future<bool> checkAndRequestPermissions() async {
    // ⬇️ 수정: API 호출 이름을 `isHealthDataAvailable`로 수정합니다. ⬇️
    final bool isAvailable = await _health.isHealthConnectAvailable();// ◀️ isHealthDataAvailable 사용

    // 1. Health Connect 설치 확인
    if (!isAvailable) {
      print("Health Connect 앱을 찾을 수 없습니다.");
      return false;
    }

    // 2. 권한 요청할 데이터 타입 정의 (수면 READ만)
    final List<HealthDataType> readTypes = [
      HealthDataType.SLEEP_ASLEEP,
      HealthDataType.SLEEP_AWAKE,
      HealthDataType.SLEEP_DEEP,
      HealthDataType.SLEEP_REM,
      HealthDataType.SLEEP_LIGHT,
    ];
    final List<HealthDataType> writeTypes = [];

    // 3. 권한 요청
    final bool granted = await _health.requestAuthorization(readTypes);

    if (granted) {
      print("Health SDK 권한 승인됨. 수면 데이터 접근 가능.");
    } else {
      print("Health SDK 권한 거부됨.");
    }
    return granted;
  }

  // 권한 요청 (수면 READ만)
  Future<bool> requestAuthorization(List<HealthDataType> readTypes) async {
    try {
      // READ 권한만 사용
      final types = readTypes;

      final granted = await _health.requestAuthorization(
        types,
        permissions: List.filled(types.length, HealthDataAccess.READ),
      );

      return granted;
    } catch (e) {
      print('Error requesting authorization: $e');
      return false;
    }
  }

  // 수면 데이터 가져오기 (세부 수면 단계별 데이터 로드)
  Future<List<HealthDataPoint>> getSleepSessions(DateTime startTime, DateTime endTime) async {
    try {
      final types = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
      ];

      final sessions = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: endTime,
      );

      return sessions;
    } catch (e) {
      print('Error getting sleep sessions: $e');
      return [];
    }
  }

  // ❌ 걸음 수 데이터 가져오기 함수 제거

  // ❌ 심박수 데이터 가져오기 함수 제거

  // 수면 데이터 가져오기 및 DB 동기화 (핵심 로직)
  Future<void> fetchAndSyncSleepData() async {
    try {
      final now = DateTime.now();
      // 지난 7일간의 데이터를 가져옵니다.
      final startTime = DateTime(now.year, now.month, now.day - 7);
      final endTime = now;

      final types = [
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_AWAKE,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_LIGHT,
      ];

      // 1. 권한 확인 (권한이 없으면 요청합니다.)
      bool hasPermission = await _health.hasPermissions(
        types,
        permissions: List.filled(types.length, HealthDataAccess.READ),
      ) ?? false;

      if (!hasPermission) {
        final granted = await _health.requestAuthorization(
          types,
          permissions: List.filled(types.length, HealthDataAccess.READ),
        );

        if (!granted) {
          print('수면 데이터 권한이 거부되었습니다. 동기화 중단.');
          return;
        }
      }

      // 2. Health Connect에서 수면 데이터 가져오기
      final sleepData = await _health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: endTime,
      );

      print('가져온 수면 데이터: ${sleepData.length}개');

      // 3. 날짜별 수면 시간 합산
      final Map<String, int> dailySleepTotals = {};

      for (var dataPoint in sleepData) {
        // SLEEP_ASLEEP (실제 잠든 시간) 데이터만 합산 (가장 일반적인 수면 시간 정의)
        if (dataPoint.type == HealthDataType.SLEEP_ASLEEP) {
          final dateKey = DateFormat('yyyy-MM-dd').format(dataPoint.dateFrom);
          final duration = dataPoint.dateTo.difference(dataPoint.dateFrom).inMinutes;

          dailySleepTotals[dateKey] = (dailySleepTotals[dateKey] ?? 0) + duration;
        }
      }

      // 4. DailyRecord DB에 저장 또는 갱신
      for (var entry in dailySleepTotals.entries) {
        final recordDate = DateTime.parse(entry.key);
        final totalMinutes = entry.value;

        // DB에서 기존 기록을 찾거나 새 기록을 만듭니다.
        final existingRecord = DatabaseManager.dailyRecordsBox.values.cast<DailyRecord>().firstWhere(
              (record) => DateFormat('yyyy-MM-dd').format(record.date) == entry.key,
          orElse: () => DailyRecord(date: recordDate),
        );

        // 수면 시간 업데이트
        existingRecord.sleepDurationMinutes = totalMinutes;
        // 힐링 시간(TES)은 앱 자체에서 기록했을 것으로 보고, 덮어쓰지 않습니다.

        // HiveObject의 save() 메서드가 필요하며, DailyRecord 모델은 HiveObject를 상속해야 합니다.
        await existingRecord.save();
      }

      print("Health Connect 수면 데이터 동기화 및 DB 저장 완료.");

    } catch (e) {
      print('수면 데이터 동기화 오류: $e');
    }
  }

  // 모든 일일 기록 가져오기 (DB 모델에 맞게 정리)
  List<DailyRecord> getAllDailyRecords() {
    // DatabaseManager를 통해 Hive DB에서 모든 DailyRecord를 가져옵니다.
    final records = DatabaseManager.getAllDailyRecords();

    // ⚠️ DB에 데이터가 전혀 없을 경우, 최근 7일간의 더미 레코드를 생성하여 UI 렌더링 오류 방지
    if (records.isEmpty) {
      final now = DateTime.now();
      final tempRecords = <DailyRecord>[];
      for (int i = 0; i < 7; i++) {
        final date = DateTime(now.year, now.month, now.day - i);
        tempRecords.add(DailyRecord(
          date: date,
          sleepDurationMinutes: 0,
          totalHealingDuration: 0,
          // DB 모델에 없는 'steps'와 'heartRate' 필드 제거
        ));
      }
      return tempRecords;
    }
    return records;
  }

// ❌ 특정 날짜의 일일 기록 가져오기 함수 제거 (steps, heartRate 의존성 제거)

// ❌ 권한 확인 (READ만) 함수 제거 (fetchAndSyncSleepData 함수에 통합)

}