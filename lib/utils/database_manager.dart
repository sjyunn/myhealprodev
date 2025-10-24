// lib/utils/database_manager.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../models/daily_record.dart';
import '../models/tes_session.dart';

class DatabaseManager {
  static const String dailyRecordBoxName = 'dailyRecords';
  static const String tesSessionBoxName = 'tesSessions';

  // 1. Hive 초기화 및 Adapter 등록
  static Future<void> initialize() async {
    // Hive 초기화 (Flutter 환경)
    await Hive.initFlutter();

    // 생성된 TypeAdapter를 등록
    if (!Hive.isAdapterRegistered(DailyRecordAdapter().typeId)) {
      Hive.registerAdapter(DailyRecordAdapter());
    }
    if (!Hive.isAdapterRegistered(TesSessionAdapter().typeId)) {
      Hive.registerAdapter(TesSessionAdapter());
    }

    // 2. 사용할 박스(Box, 테이블과 유사)를 미리 엽니다.
    await Hive.openBox<DailyRecord>(dailyRecordBoxName);
    await Hive.openBox<TesSession>(tesSessionBoxName);
  }

  // 3. DailyRecord Box에 접근하는 Getter
  static Box<DailyRecord> get dailyRecordsBox => Hive.box<DailyRecord>(dailyRecordBoxName);

  // 4. TesSession Box에 접근하는 Getter
  static Box<TesSession> get tesSessionsBox => Hive.box<TesSession>(tesSessionBoxName);

  // 5. DB에 저장된 모든 일별 기록을 가져오는 함수 (분석용)
  static List<DailyRecord> getAllDailyRecords() {
    return dailyRecordsBox.values.toList();
  }
}