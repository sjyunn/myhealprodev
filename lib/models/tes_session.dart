// lib/models/tes_session.dart

import 'package:hive/hive.dart';

part 'tes_session.g.dart';

@HiveType(typeId: 1) // 1번 TypeId (DailyRecord와 중복되지 않도록)
class TesSession extends HiveObject {
  @HiveField(0)
  late DateTime startTime; // 세션 시작 시간

  @HiveField(1)
  late int durationMinutes; // 실제 사용 시간 (분 단위)

  @HiveField(2)
  late int mode; // 모드 (1:학습, 2:수면, 3:힐링)

  @HiveField(3)
  late int intensityMax; // 해당 세션의 최대 세기

  @HiveField(4)
  late DateTime endTime; // 세션 종료 시간

  TesSession({
    required this.startTime,
    required this.endTime,
    this.durationMinutes = 0,
    this.mode = 1,
    this.intensityMax = 0,
  }) {
    // 생성자에서 지속 시간 자동 계산
    durationMinutes = endTime.difference(startTime).inMinutes;
  }
}