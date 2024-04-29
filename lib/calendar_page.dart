import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_planner/time_planner.dart';
import 'package:workout_tracker/home_page.dart';
import 'database_helper.dart';
import 'main.dart';

bool initialStartup = true;
late Function querySingleEventToCalendar;
late Function queryAllEventsToCalendar;
late Function insertEventIntoDatabase;
late Function addEventToCalendar;

class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  CalendarPageState createState() => CalendarPageState();
}

class CalendarPageState extends State<CalendarPage> {
  List<TimePlannerTask> tasks = [];

  void addDateIntoCalendar(TimePlannerDateTime planner, int duration, Color color, int reps, int sets, String name, int eventId, bool snackbar) {
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
                height: 400,
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
                          child: const Text("Edit Exercise"),
                          onPressed: () async {
                            final dbHelper = DatabaseHelper.instance;
                            final event = await dbHelper.queryEventAndExerciseById(eventId);
                            List? ret = await addEventToCalendar(true, event[0]["name"], event[0]["reps"].toString(), event[0]["sets"].toString());
                            if (ret != null) {
                              await dbHelper.updateEventById(eventId, "${ret[0]}/${ret[1]}", "${ret[2]}:${ret[3]}",
                                  ret[4], ret[5]);
                              await dbHelper.updateExerciseById(eventId, ret[6], ret[7], ret[8]);

                              Navigator.pop(context);
                              tasks.removeWhere((task) => task.dateTime == planner);
                              querySingleEventToCalendar(eventId);
                              setState(() { tasks; });
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Edited exercise!')));
                            } else {
                              Navigator.pop(context);
                            }
                          }
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton(
                          child: const Text("Remove Exercise"),
                          onPressed: () async {
                            final dbHelper = DatabaseHelper.instance;
                            await dbHelper.deleteEventAndExerciseById(eventId);

                            Navigator.pop(context);
                            tasks.removeWhere((task) => task.dateTime == planner);
                            setState(() { tasks; });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removed exercise!')));
                          }
                      ),
                      const SizedBox(height: 10),
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

    if (snackbar) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added exercise!')));
  }

  @override
  Widget build(BuildContext context) {
    final dbHelper = DatabaseHelper.instance;

    querySingleEventToCalendar = (int eventId) async {
      final event = await dbHelper.queryEventAndExerciseById(eventId);
      int month = int.parse(event[0]["start_date"].toString().substring(0,2));
      int day = int.parse(event[0]["start_date"].toString().substring(3));
      int hour = int.parse(event[0]["start_time"].toString().substring(0,2));
      int minute = int.parse(event[0]["start_time"].toString().substring(3));
      int duration = int.parse(event[0]["total_duration"].toString());
      int color = int.parse(event[0]["color"].toString());
      int reps = event[0]["reps"];
      int sets = event[0]["sets"];
      String name = event[0]["name"];

      DateTime now = DateTime.now();
      int todayMo = int.parse(DateFormat("MM").format(now));
      int todayDay = int.parse(DateFormat("dd").format(now));
      if (month == todayMo && (day - todayDay >= 0)) {
        TimePlannerDateTime dateTime = TimePlannerDateTime(
            day: day - todayDay,
            hour: hour,
            minutes: minute
        );
        addDateIntoCalendar(dateTime, duration, Color(color), reps, sets, name, eventId, false);
      }
    };

    queryAllEventsToCalendar = () async {
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
          addDateIntoCalendar(dateTime, duration, Color(color), reps, sets, name, eventId, false);
        }
      }
    };

    if (initialStartup) {
      queryAllEventsToCalendar();
      initialStartup = false;
    }

    insertEventIntoDatabase = (int month, int day, int hour, int minute, int duration, int color, int reps, int sets, String name) async {
      String mm, dd, hr, min;
      mm = (month < 10) ? "0$month" : month.toString();
      dd = (day < 10) ? "0$day" : day.toString();
      hr = (hour < 10) ? "0$hour" : hour.toString();
      min = (minute < 10) ? "0$minute" : minute.toString();

      await dbHelper.insertEvent(("$mm/$dd"), ("$hr:$min"), duration, color);
      await dbHelper.insertExercise(reps, sets, name);
    };



    DateTime day1 = DateTime.now();
    DateTime day2 = DateTime(day1.year, day1.month, day1.day + 1);
    DateTime day3 = DateTime(day1.year, day1.month, day1.day + 2);
    DateTime day4 = DateTime(day1.year, day1.month, day1.day + 3);
    DateTime day5 = DateTime(day1.year, day1.month, day1.day + 4);
    DateTime day6 = DateTime(day1.year, day1.month, day1.day + 5);
    DateTime day7 = DateTime(day1.year, day1.month, day1.day + 6);

    DateTime selectedDate = day1;
    TimeOfDay selectedTime = TimeOfDay.now();
    TimePlannerDateTime planner;

    Future<DateTime?> pickDateMenu() async {
      final selected = await showDatePicker(context: context, initialDate: selectedDate, firstDate: day1, lastDate: day7);
      if (selected != null && selected != selectedDate) setState(() { selectedDate = selected; });
      else if (selected == null) return null;
      return selectedDate;
    }

    Future<TimeOfDay?> pickTimeMenu() async {
      final selected = await showTimePicker(context: context, initialTime: selectedTime,);
      if (selected != null && selected != selectedTime) setState(() { selectedTime = selected; });
      else if (selected == null) return null;
      return selectedTime;
    }

    String reps = "", sets = "", name = "";
    GlobalKey<FormState> formKey = GlobalKey<FormState>();
    Future<void> enterTextMenu(String type, String initVal) async {
      return await showDialog(
          context: context,
          builder: (context) {
            final TextEditingController controller = TextEditingController(text: initVal);
            return StatefulBuilder(builder: (context, setState) {
              return AlertDialog(
                content: Form(
                    key: formKey,
                    child: Column(children: [
                      TextFormField(
                        controller: controller,
                        validator: (value) {
                          return value!.isNotEmpty ? null : 'Invalid field';
                        },
                        decoration: InputDecoration(hintText: "Enter ${type == "name" ? "exercise name:" : "number of $type"}"),
                      ),
                    ])),
                actions: <Widget>[
                  TextButton(
                      child: const Text("SUBMIT"),
                      onPressed: () {
                        if (formKey.currentState!.validate()) Navigator.of(context).pop();
                        if (type == "reps") reps = controller.text;
                        else if (type == "sets") sets = controller.text;
                        else if (type == "name") name = controller.text;
                      })
                ],
              );
            });
          });
    }

    addEventToCalendar = (bool editMode, String detailInit, String repInit, String setInit) async {
      // get starting date
      final date = await pickDateMenu();
      if (date == null) return null;
      // get starting time
      final startTime = await pickTimeMenu();
      if (startTime == null) return null;
      // get ending time
      final endTime = await pickTimeMenu();
      if (endTime == null) return null;

      // check if times are valid
      if (endTime.hour < startTime.hour) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time cannot be earlier than start time!')));
        return null;
      } else if (endTime.hour == startTime.hour && endTime.minute < startTime.minute) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time cannot be earlier than start time!')));
        return null;
      } else if (endTime.hour == startTime.hour && endTime.minute == startTime.minute) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('End time cannot be the same as start time!')));
        return null;
      }

      // get exercise name, reps, and sets from user
      await enterTextMenu("name", detailInit);
      if (name == "") return null;
      await enterTextMenu("reps", repInit);
      if (reps == "") return null;
      await enterTextMenu("sets", setInit);
      if (sets == "") return null;

      // convert time into duration
      int duration = (endTime.hour - startTime.hour) * 60 + (endTime.minute - startTime.minute);
      int mm = day1.month;
      int dd = date.day;
      int hr = startTime.hour + 1;
      int min = startTime.minute;

      // generate random color
      List<Color?> colors = [
        Colors.purple,
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.red,
      ];
      Color color = colors[Random().nextInt(colors.length)]!;

      int eventId = await dbHelper.getLastInsertId() + 1;

      // insert into calendar and database
      if (!editMode) {
        setState(() {
          planner = TimePlannerDateTime(
              day: dd - int.parse(DateFormat("dd").format(day1)),
              hour: hr,
              minutes: min);

          addDateIntoCalendar(planner, duration, color, int.parse(reps), int.parse(sets), name, eventId, true); // add into calendar display
          insertEventIntoDatabase(mm, dd, hr, min, duration, color.value, int.parse(reps), int.parse(sets), name); // save into database
          print("Added Exercise: $name with $reps reps and $sets sets on $mm/$dd at $hr:$min");
        });
      }

      return [(mm < 10) ? "0$mm" : mm.toString(), (dd < 10) ? "0$dd" : dd.toString(), (hr < 10) ? "0$hr" : hr.toString(), (min < 10) ? "0$min" : min.toString(), duration, color.value, int.parse(reps), int.parse(sets), name];
    };

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: Center(
        child: TimePlanner(
          startHour: 6,
          endHour: 23,
          style: TimePlannerStyle(
            cellHeight: 40,
            cellWidth: 80,
            showScrollBar: true,
          ),
          headers: [
            TimePlannerTitle(
              date: DateFormat.yMd().format(day1),
              title: DateFormat.EEEE().format(day1),
            ),
            TimePlannerTitle(
              date: DateFormat.yMd().format(day2),
              title: DateFormat.EEEE().format(day2),
            ),
            TimePlannerTitle(
              date: DateFormat.yMd().format(day3),
              title: DateFormat.EEEE().format(day3),
            ),
            TimePlannerTitle(
              date: DateFormat.yMd().format(day4),
              title: DateFormat.EEEE().format(day4),
            ),
            TimePlannerTitle(
              date: DateFormat.yMd().format(day5),
              title: DateFormat.EEEE().format(day5),
            ),
            TimePlannerTitle(
              date: DateFormat.yMd().format(day6),
              title: DateFormat.EEEE().format(day6),
            ),
            TimePlannerTitle(
              date: DateFormat.yMd().format(day7),
              title: DateFormat.EEEE().format(day7),
            ),
          ],
          tasks: tasks,
        ),
      ),

      // button to add new exercise
      floatingActionButton: FloatingActionButton(
        onPressed: () => addEventToCalendar(false, "", "", ""),
        tooltip: 'Add Exercise',
        child: const Icon(Icons.add),
      ),
    );
  }
}