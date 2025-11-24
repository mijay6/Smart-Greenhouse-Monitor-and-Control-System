import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

//part 'drift_database.g.dart';

class SensorReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get temperature => real()();
  RealColumn get humidity => real()();
  IntColumn get lightLevel => integer()();
  RealColumn get soilMoisture => real()();
  DateTimeColumn get timestamp => dateTime()();
}

class Alerts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()();
  TextColumn get message => text()();
  TextColumn get severity => text()();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();
  DateTimeColumn get timestamp => dateTime()();
}
/*
@DriftDatabase(tables: [SensorReadings, Alerts])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'greenhouse.db'));
      return NativeDatabase(file);
    });
  }
}
*/