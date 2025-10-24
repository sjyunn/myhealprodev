// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tes_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TesSessionAdapter extends TypeAdapter<TesSession> {
  @override
  final int typeId = 1;

  @override
  TesSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TesSession(
      startTime: fields[0] as DateTime,
      endTime: fields[4] as DateTime,
      durationMinutes: fields[1] as int,
      mode: fields[2] as int,
      intensityMax: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TesSession obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.startTime)
      ..writeByte(1)
      ..write(obj.durationMinutes)
      ..writeByte(2)
      ..write(obj.mode)
      ..writeByte(3)
      ..write(obj.intensityMax)
      ..writeByte(4)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TesSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
