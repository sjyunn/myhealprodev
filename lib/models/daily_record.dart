// lib/models/daily_record.dart

import 'package:hive/hive.dart';

// ⚠️ 이 파일이 있어야 build_runner가 정상 작동합니다.
part 'daily_record.g.dart';

@HiveType(typeId: 0)
class DailyRecord extends HiveObject { // ◀️ HiveObject 상속 유지

  // ⬇️ final 키워드는 HiveObject에서 제거하고 late를 사용합니다. ⬇️
  @HiveField(0)
  late DateTime date;

  @HiveField(1)
  late int sleepDurationMinutes; // ◀️ Health Connect 수면 시간

  @HiveField(2)
  late int totalHealingDuration; // ◀️ TES 사용 시간 합산

  // ❌ steps와 heartRate 필드는 제거되었습니다.

  DailyRecord({
    required this.date,
    this.sleepDurationMinutes = 0,
    this.totalHealingDuration = 0,
  });

// ⚠️ Note: 이전에 JSON/copyWith 같은 메서드도 제거되었습니다.
// Health Connect SDK 통합을 위해 필요한 최소한의 구조입니다.
}