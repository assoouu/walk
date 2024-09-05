import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/mountain_route.dart';

class MountainTrailService {
  Database? _database;

  Future<void> initializeDatabase() async {
    if (_database != null) return;
    _database = await openDatabase(
      join(await getDatabasesPath(), 'mountain_trails.db'),
    );
  }

  Future<List<MountainRoute>> fetchTrailInfo(String mountainName) async {
    final List<Map<String, dynamic>> maps = await _database!.query(
      'trails',
      where: 'trail_name = ?',
      whereArgs: [mountainName],
    );

    return List.generate(maps.length, (i) {
      return MountainRoute.fromMap(maps[i]);
    });
  }

  Future<void> closeDatabase() async {
    await _database?.close();
  }
}
