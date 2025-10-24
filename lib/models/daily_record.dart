// lib/models/daily_record.dart

import 'package:hive/hive.dart';

// HiveGenerator가 이 파일을 분석하도록 part 파일 지정 (필수)
part 'daily_record.g.dart';

@HiveType(typeId: 0) // 0번 TypeId
class DailyRecord extends HiveObject {
  @HiveField(0)
  late DateTime date; // 기준 날짜 (시간 정보는 제외, YYYY-MM-DD)

  @HiveField(1)
  late int sleepDurationMinutes; // Health Connect에서 가져온 총 수면 시간 (분)

  @HiveField(2)
  late int totalHealingDuration; // 모든 TES 세션들의 합산 사용 시간 (분)

  @HiveField(3)
  late int tensCount; // 총 TENS 수행 횟수 (예시)

  DailyRecord({
    required this.date,
    this.sleepDurationMinutes = 0,
    this.totalHealingDuration = 0,
    this.tensCount = 0,
  });
}