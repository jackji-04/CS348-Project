import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:workout_tracker/database_helper.dart';
import 'main.dart';
import 'orm_helper.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({Key? key}) : super(key: key);

  @override
  StatsPageState createState() => StatsPageState();
}

class StatsPageState extends State<StatsPage> {
  DateTime? selectedStart;
  DateTime? selectedEnd;
  List<String> dropdownItems = ["———"];
  String dropdownValue = "———";

  String exerciseName = "";
  int totalSessions = 0;
  int totalReps = 0;
  int totalSets = 0;
  int averageReps = 0;
  int averageSets = 0;

  final dbHelper = DatabaseHelper.instance;
  List<Exercise> exercises = [];
  List<Rep> reps = [];
  List<Set> sets = [];

  @override
  void initState() {
    super.initState();
    populateData();
  }

  Future<void> populateData() async {
    ExerciseList exerciseList = ExerciseList();
    exercises = await exerciseList.getList();
  }

  Future<void> populateSummary(String exercise) async {
    RepList repList = RepList();
    SetList setList = SetList();
    reps = await repList.getList(exercise);
    sets = await setList.getList(exercise);

    exerciseName = exercise;
    totalSessions = reps.length;

    int sum = 0;
    int count = 0;
    for (Rep rep in reps) {
      if (rep.date.isAfter(selectedStart!) && rep.date.isBefore(selectedEnd!)) {
        sum += rep.reps;
        count++;
      }
    }
    averageReps = (sum / count).truncate();
    totalReps = sum;

    sum = 0;
    count = 0;
    for (Set set in sets) {
      if (set.date.isAfter(selectedStart!) && set.date.isBefore(selectedEnd!)) {
        sum += set.sets;
        count++;
      }
    }
    averageSets = (sum / count).truncate();
    totalSets = sum;

    setState(() {});
  }

  Future<void> selectDate(BuildContext context, bool isStartDate) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        if (isStartDate) {
          selectedStart = pickedDate;
        } else {
          selectedEnd = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, 23, 59);
        }
        updateDropdown();
      });
    }
  }

  void updateDropdown() {
    if (selectedStart != null && selectedEnd != null) {
      dropdownItems.clear();
      dropdownItems.add("———");
      setState(() {
        dropdownValue = "———";
        exerciseName = "";
        totalSessions = 0;
        totalReps = 0;
        totalSets = 0;
        averageReps = 0;
        averageSets = 0;
      });

      if (selectedEnd!.isAfter(selectedStart!)) {
        for (Exercise exer in exercises) {
          if (exer.date.isAfter(selectedStart!)
              && exer.date.isBefore(selectedEnd!)
              && !dropdownItems.contains(exer.name)) {
            dropdownItems.add(exer.name);
          }
        }
      }
    }
  }

  Future<void> updateSummary(String exercise) async {
    setState(() {
      dropdownValue = exercise;
    });

    if (exercise != "———") {
      await populateSummary(exercise);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 70),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () => selectDate(context, true),
                  child: Text(selectedStart == null
                      ? 'Select Start Date'
                      : DateFormat('MM/dd/yyyy').format(selectedStart!)),
                ),
                ElevatedButton(
                  onPressed: () => selectDate(context, false),
                  child: Text(selectedEnd == null
                      ? 'Select End Date'
                      : DateFormat('MM/dd/yyyy').format(selectedEnd!)),
                ),
              ]
            ),

            const SizedBox(height: 30),
            const Text('Select Exercise Type:'),
            DropdownButton<String>(
              value: dropdownValue,
              items: dropdownItems
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) async => await updateSummary(newValue!)
            ),

            const SizedBox(height: 30),
            const Divider(),
            const SizedBox(height: 20),
            const Text('Exercise Stats Summary', textAlign: TextAlign.center),
            const SizedBox(height: 20),

            // Information Text Boxes
            Expanded( // Allow info boxes to occupy remaining space
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text('Exercise Name: $exerciseName'),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text('Total Sessions: $totalSessions'),
                  ),
                  const SizedBox(height: 25),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text('Total Reps: $totalReps'),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text('Total Sets: $totalSets'),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text('Average Reps: $averageReps'),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: Text('Average Sets: $averageSets'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
