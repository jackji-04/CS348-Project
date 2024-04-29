import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'orm_helper.dart';

class DatabaseHelper {
  static const databaseName = "exercise_calendar.db";
  static const eventTable = "Event";
  static const exerciseTable = "Exercise";

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? db;
  Future<Database?> get database async {
    if (db != null) return db;
    db = await _createDatabase();
    return db;
  }

  _createDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, databaseName);
    return await openDatabase(path,
        version: 1,
        onCreate: (Database db, int version) async {
          await db.execute('''
          CREATE TABLE $eventTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            start_date TEXT NOT NULL,
            start_time TEXT NOT NULL,
            total_duration INTEGER NOT NULL,
            color INTEGER NOT NULL,
            complete INTEGER DEFAULT 0
          );
          ''');
          await db.execute('''
          CREATE TABLE $exerciseTable(
            event_id INTEGER PRIMARY KEY AUTOINCREMENT,
            reps INTEGER NOT NULL,
            sets INTEGER NOT NULL,
            name TEXT NOT NULL
          );
          ''');
          await db.execute('''
          CREATE INDEX idx_event_complete ON $eventTable (complete);
          '''); // index on complete to quickly find completed exercises
          await db.execute('''
          CREATE INDEX idx_exercise_name ON $exerciseTable (LOWER(name));
          '''); // index on name to quickly find exercises by name
        });
  }

  Future<void> initialize() async {
    Database? db = await instance.database;
  }

  Future<int> insertEvent(String startDate, String startTime, int totalDuration, int color) async {
    Database? db = await instance.database;
    return await db!.rawInsert('''
    INSERT INTO $eventTable (start_date, start_time, total_duration, color)
    VALUES (?, ?, ?, ?);
    ''', [startDate, startTime, totalDuration, color]);
  }

  Future<int> insertExercise(int reps, int sets, String name) async {
    Database? db = await instance.database;
    return await db!.rawInsert('''
    INSERT INTO $exerciseTable (reps, sets, name)
    VALUES (?, ?, ?);
    ''', [reps, sets, name]);
  }

  Future<List<Map<String, dynamic>>> queryAllEvents() async {
    Database? db = await instance.database;
    return await db!.rawQuery('''
    SELECT * FROM $eventTable;
    ''');
  }

  Future<List<Map<String, dynamic>>> queryEventById(int eventId) async {
    Database? db = await instance.database;
    return await db!.rawQuery('''
    SELECT * FROM $eventTable
    WHERE id = ?;
    ''', [eventId]);
  }

  // Future<List<Map<String, dynamic>>> queryEventByDate(String date) async {
  //   Database? db = await instance.database;
  //   return await db!.rawQuery('''
  //   SELECT * FROM $eventTable
  //   WHERE start_date = ?;
  //   ''', [date]);
  // }

  Future<List<Map<String, dynamic>>> queryExerciseById(int eventId) async {
    Database? db = await instance.database;
    return await db!.rawQuery('''
    SELECT * FROM $exerciseTable
    WHERE event_id = ?;
    ''', [eventId]);
  }

  Future<List<Map<String, dynamic>>> queryAllEventsWithExercise() async {
    Database? db = await instance.database;
    return await db!.rawQuery('''
    SELECT Event.*, Exercise.reps, Exercise.sets, Exercise.name
    FROM Event
    JOIN Exercise ON Exercise.event_id = Event.id;
    ''');
  }

  Future<List<Map<String, dynamic>>> queryEventAndExerciseById(int eventId) async {
    Database? db = await instance.database;
    return await db!.rawQuery('''
    SELECT Event.*, Exercise.reps, Exercise.sets, Exercise.name
    FROM Event
    JOIN Exercise ON Exercise.event_id = Event.id
    WHERE Event.id = ?;
    ''', [eventId]);
  }

  Future<List<Map<String, dynamic>>> queryEventAndExerciseByDate(String date) async {
    Database? db = await instance.database;
    return await db!.rawQuery('''
    SELECT Event.*, Exercise.reps, Exercise.sets, Exercise.name
    FROM Event
    JOIN Exercise ON Exercise.event_id = Event.id
    WHERE Event.start_date = ?;
    ''', [date]);
  }

  Future<int> deleteEventById(int eventId) async {
    Database? db = await instance.database;
    return await db!.rawDelete('''
    DELETE FROM $eventTable
    WHERE id = ?;
    ''', [eventId]);
  }

  // Future<int> deleteEventByDate(String date) async {
  //   Database? db = await instance.database;
  //   return await db!.rawDelete('''
  //   DELETE FROM $eventTable
  //   WHERE start_date = ?;
  //   ''', [date]);
  // }

  Future<int> deleteExerciseById(int eventId) async {
    Database? db = await instance.database;
    return await db!.rawDelete('''
    DELETE FROM $exerciseTable
    WHERE event_id = ?;
    ''', [eventId]);
  }

  Future<void> deleteEventAndExerciseById(int eventId) async {
    // Database? db = await instance.database;
    // await db!.rawDelete('''
    // DELETE FROM $eventTable
    // WHERE id = ?;
    // ''', [eventId]);
    // return await db.rawDelete('''
    // DELETE FROM $exerciseTable
    // WHERE event_id NOT IN (SELECT DISTINCT event_id FROM Event);
    // ''');
    await deleteEventById(eventId);
    await deleteExerciseById(eventId);
  }

  // Future<int> deleteEventAndExerciseByDate(String date) async {
  //   Database? db = await instance.database;
  //   await db!.rawDelete('''
  //   DELETE FROM $eventTable
  //   WHERE start_date = ?;
  //   ''', [date]);
  //   return await db.rawDelete('''
  //   DELETE FROM $exerciseTable
  //   WHERE event_id NOT IN (SELECT DISTINCT event_id FROM Event);
  //   ''');
  // }

  Future<int> updateEventById(int eventId, String startDate, String startTime, int totalDuration, int color) async {
    Database? db = await instance.database;
    return await db!.rawUpdate('''
    UPDATE $eventTable
    SET start_date = ?, start_time = ?, total_duration = ?, color = ?
    WHERE id = ?;
    ''', [startDate, startTime, totalDuration, color, eventId]);
  }

  Future<int> updateExerciseById(int eventId, int reps, int sets, String name) async {
    Database? db = await instance.database;
    return await db!.rawUpdate('''
    UPDATE $exerciseTable
    SET reps = ?, sets = ?, name = ?
    WHERE event_id = ?;
    ''', [reps, sets, name, eventId]);
  }

  Future<int> markEventCompleteById(int eventId) async {
    Database? db = await instance.database;
    return await db!.rawUpdate('''
    UPDATE $eventTable
    SET complete = 1
    WHERE id = ?;
    ''', [eventId]);
  }

  Future<int> getLastInsertId() async {
    Database? db = await instance.database;
    List<Map<String, dynamic>> seq = await db!.rawQuery('''
    SELECT seq FROM sqlite_sequence
    WHERE name = '$eventTable';
    ''');
    return seq.isEmpty ? 0 : seq[0]["seq"];
  }
}