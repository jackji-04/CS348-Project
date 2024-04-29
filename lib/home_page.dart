import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_planner/time_planner.dart';
import 'database_helper.dart';
import 'main.dart';

bool mainFirst = true;

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<TimePlannerTask> tasks = [];

  void addDateIntoCalendar(TimePlannerDateTime planner, int duration, Color color, int reps, int sets, String name, int eventId) {
    setState(() {
      tasks.add(
        TimePlannerTask(
          color: color,
          dateTime: planner,
          minutesDuration: duration,
          daysDuration: 1,
          onTap: () {
            showModalBottomSheet(context: context, builder: (BuildContext context) {
              return SizedBox(
                  height: 250,
                  child: Center(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                                padding: EdgeInsets.all(8.0),
                                child: TextField(enabled: false, decoration: InputDecoration(hintText: "Reps: ${reps.toString()}"))
                            ),
                            Padding(
                                padding: EdgeInsets.all(8.0),
                                child: TextField(enabled: false, decoration: InputDecoration(hintText: "Sets: ${sets.toString()}"))
                            ),
                            ElevatedButton(
                                child: const Text("Mark Complete"),
                                onPressed: () async {
                                  final dbHelper = DatabaseHelper.instance;
                                  await dbHelper.markEventCompleteById(eventId);

                                  Navigator.pop(context);
                                  tasks.removeWhere((task) => task.dateTime == planner);
                                  setState(() { tasks; });
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Completed exercise!')));
                                }
                            )
                          ]
                      )
                  )
              );
            });
          },
          child: Text(
            name,
            style: TextStyle(color: Colors.grey[350], fontSize: 12),
          ),
        ),
      );
    });

    if(!mainFirst) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Added exercise!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper.instance;
    if (mainFirst) {
      void queryEventsToCalendar() async {
        final events = await dbHelper.queryAllEventsWithExercise();
        for (int i = 0; i < events.length; i++) {
          if (events[i]["complete"] == 1) continue;

          int eventId = events[i]["id"];
          int month = int.parse(events[i]["start_date"].toString().substring(0,2));
          int day = int.parse(events[i]["start_date"].toString().substring(3));
          int hour = int.parse(events[i]["start_time"].toString().substring(0,2));
          int minute = int.parse(events[i]["start_time"].toString().substring(3));
          int duration = int.parse(events[i]["total_duration"].toString());
          int color = int.parse(events[i]["color"].toString());
          int reps = events[i]["reps"];
          int sets = events[i]["sets"];
          String name = events[i]["name"];

          DateTime now = DateTime.now();
          int todayMo = int.parse(DateFormat("MM").format(now));
          int todayDay = int.parse(DateFormat("dd").format(now));
          if (month == todayMo && (day - todayDay >= 0)) {
            TimePlannerDateTime dateTime = TimePlannerDateTime(
                day: day - todayDay,
                hour: hour,
                minutes: minute
            );
            addDateIntoCalendar(dateTime, duration, Color(color), reps, sets, name, eventId);
          }
        }
        mainFirst = false;
      }
      queryEventsToCalendar();
    }

    DateTime day1 = DateTime.now();
    return MaterialApp(
      theme: getDarkTheme(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Welcome to Today's Todo!"),
          centerTitle: true,
          toolbarHeight: 40,
        ),
        body: Center(
          child: TimePlanner(
            startHour: 6,
            endHour: 23,
            style: TimePlannerStyle(
              cellHeight: 50,
              cellWidth: 300,
              showScrollBar: true,
            ),
            headers: [
              TimePlannerTitle(
                date: DateFormat.yMd().format(day1),
                title: DateFormat.EEEE().format(day1),
              ),
            ],
            tasks: tasks,
          ),
        ),
      ),
    );
  }
}
