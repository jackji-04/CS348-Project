import 'package:flutter/material.dart';
import 'calendar_page.dart';
import 'database_helper.dart';
import 'home_page.dart';
import 'orm_helper.dart';
import 'statistics_page.dart';

bool del = false;
final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

void main() async {
  runApp(Main());

  final dbHelper = DatabaseHelper.instance;
  dbHelper.initialize();
  void queryAll() async {
    final allRows = await dbHelper.queryAllEventsWithExercise();
    print('Database query:');
    for(int i = 0; i < allRows.length; i++) {
      print(allRows[i]);
    }
  }
  queryAll();
}

final darkTheme = ThemeData(
  primarySwatch: Colors.grey,
  primaryColor: Colors.black,
  brightness: Brightness.dark,
  backgroundColor: const Color(0xFF212121),
  // accentColor: Colors.white,
  // accentIconTheme: const IconThemeData(color: Colors.black),
  dividerColor: Colors.black12,
);

getDarkTheme() {
  return darkTheme;
}

class Main extends StatelessWidget {
  Main({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: darkTheme,
      title: "Workout Tracker",
      navigatorKey: navKey,
      home: const NavBar(),
    );
  }
}

class NavBar extends StatefulWidget {
  const NavBar({Key? key}) : super(key: key);

  @override
  NavBarState createState() => NavBarState();
}

const List<Widget> widgetOpt = <Widget>[
  CalendarPage(),
  HomePage(),
  StatsPage(),
];
int globalIndex = 1;

class NavBarState extends State<NavBar> {
  void onItemTap(int i) {
    setState(() {
      globalIndex = i;
    });
    if (globalIndex == 0) {
      initialStartup = true;
    } if (globalIndex == 1) {
      mainFirst = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Exercise Tracker"),
          centerTitle: true,
        ),
        body: Center(
          child: widgetOpt.elementAt(globalIndex),
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Calendar',
              backgroundColor: Colors.black12,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
              backgroundColor: Colors.black12,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.pending_actions),
              label: 'Statistics',
              backgroundColor: Colors.black12,
            ),
          ],
          type: BottomNavigationBarType.shifting,
          currentIndex: globalIndex,
          selectedItemColor: Colors.indigoAccent,
          iconSize: 40,
          onTap: onItemTap,
          elevation: 5,
        )
    );
  }
}