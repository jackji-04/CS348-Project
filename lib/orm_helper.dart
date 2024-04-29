import "package:intl/intl.dart";
import "package:sqflite/sqflite.dart";
import "package:workout_tracker/database_helper.dart";

abstract class BaseModel<T> {
  final String tableName;

  BaseModel(this.tableName);

  Future<List<T>> query(List<String> columns, String condition, List<String> args) async {
    Database? db = await DatabaseHelper.instance.database;

    List<Map<String, dynamic>> maps = await db!.query( // encapsulate querying
      tableName,
      columns: columns,
      where: condition,
      whereArgs: args,
    );
    return fromMap(maps);
  }

  List<T> fromMap(List<Map<String, dynamic>> maps);
}

class Exercise {
  String name;
  DateTime date;

  Exercise({required this.name, required this.date});

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "date": date.toString()
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map) {
    String dateStr = map["start_date"] + "/" + DateTime.now().year.toString();
    DateFormat formatter = DateFormat("MM/dd/yyyy");
    DateTime date = formatter.parse(dateStr);

    return Exercise(
      name: map["name"] as String,
      date: date
    );
  }
}

class ExerciseList extends BaseModel<Exercise> {
  ExerciseList() : super("Exercise INNER JOIN Event INDEXED BY idx_event_complete ON id = event_id");

  Future<List<Exercise>> getList() async {
    return query(
      ["LOWER(name) AS name", "reps", "start_date"],
      "complete = 1",
      [],
    );
  }

  @override
  List<Exercise> fromMap(List<Map<String, dynamic>> maps) {
    return maps.map((map) => Exercise.fromMap(map)).toList();
  }
}

class Rep {
  String name;
  int reps;
  DateTime date;

  Rep({required this.name, required this.reps, required this.date});

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "reps": reps,
      "date": date.toString()
    };
  }

  factory Rep.fromMap(Map<String, dynamic> map) {
    String dateStr = map["start_date"] + "/" + DateTime.now().year.toString();
    DateFormat formatter = DateFormat("MM/dd/yyyy");
    DateTime date = formatter.parse(dateStr);

    return Rep(
      name: map["name"] as String,
      reps: map["reps"] as int,
      date: date
    );
  }
}

class RepList extends BaseModel<Rep> {
  RepList() : super("Exercise INDEXED BY idx_exercise_name INNER JOIN Event INDEXED BY idx_event_complete ON id = event_id");

  Future<List<Rep>> getList(String exerciseName) async {
    return query(
      ["name", "reps", "start_date"],
      "complete = 1 AND LOWER(name) = LOWER(?)",
      [exerciseName],
    );
  }

  @override
  List<Rep> fromMap(List<Map<String, dynamic>> maps) {
    return maps.map((map) => Rep.fromMap(map)).toList();
  }
}

class Set {
  String name;
  int sets;
  DateTime date;

  Set({required this.name, required this.sets, required this.date});

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "sets": sets,
      "date": date
    };
  }

  factory Set.fromMap(Map<String, dynamic> map) {
    String dateStr = map["start_date"] + "/" + DateTime.now().year.toString();
    DateFormat formatter = DateFormat("MM/dd/yyyy");
    DateTime date = formatter.parse(dateStr);

    return Set(
      name: map["name"] as String,
      sets: map["sets"] as int,
      date: date
    );
  }
}

class SetList extends BaseModel<Set> {
  SetList() : super("Exercise INDEXED BY idx_exercise_name INNER JOIN Event INDEXED BY idx_event_complete ON id = event_id");

  Future<List<Set>> getList(String exerciseName) async {
    return query(
      ["name", "sets", "start_date"],
      "complete = 1 AND LOWER(name) = LOWER(?)",
      [exerciseName],
    );
  }

  @override
  List<Set> fromMap(List<Map<String, dynamic>> maps) {
    return maps.map((map) => Set.fromMap(map)).toList();
  }
}