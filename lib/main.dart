import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Work Hour Tracker',
      theme: ThemeData.dark(),
      home: const InputScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InputScreen extends StatefulWidget {
  const InputScreen({Key? key}) : super(key: key);

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  TimeOfDay? startTime;
  TimeOfDay? lunchOutTime;
  TimeOfDay? lunchInTime;
  TimeOfDay? brbOutTime;
  TimeOfDay? brbInTime;
  String endTimeString = '';
  String remainingTimeString = 'Remaining time: 00:00:00';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      endTimeString = prefs.getString('endTimeString') ?? 'Ends at: 00:00:00';  
      remainingTimeString = prefs.getString('remainingTimeString') ?? 'Remaining time: 00:00:00'; 
    });
  }


  void _selectTime(BuildContext context, String label) async {
    final useCurrentTime = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose Time'),
          content: const Text('Would you like to use the current time?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
          ],
        );
      },
    );

    TimeOfDay? picked;
    if (useCurrentTime == true) {
      picked = TimeOfDay.now();
    } else if (useCurrentTime == false) {
      picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
    }

    if (picked != null) {
      setState(() {
        switch (label) {
          case 'Start Time':
            startTime = picked;
            final now = DateTime.now();
            final todayStartTime =
                DateTime(now.year, now.month, now.day, startTime!.hour, startTime!.minute);
            final DateTime endTime = todayStartTime.add(const Duration(hours: 8));
            endTimeString = 'Ends at ${DateFormat('h:mm a').format(endTime)}';
            break;
          case 'Lunch Out Time':
            lunchOutTime = picked;
            break;
          case 'Lunch In Time':
            lunchInTime = picked;
            break;
          case 'BRB Out Time':
            brbOutTime = picked;
            break;
          case 'BRB In Time':
            brbInTime = picked;
            break;
          default:
        }
      });
      calculateAndDisplayWorkHours();
    }
  }

  void _resetAll() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored data
    setState(() {
      startTime = null;
      lunchOutTime = null;
      lunchInTime = null;
      brbOutTime = null;
      brbInTime = null;
      endTimeString = 'Ends at: 00:00:00';
      remainingTimeString = 'Remaining time: 00:00:00';
      _timer?.cancel();
    });
  }

  void calculateAndDisplayWorkHours() async {
    if (startTime != null) {
      final now = DateTime.now();
      final todayStartTime =
          DateTime(now.year, now.month, now.day, startTime!.hour, startTime!.minute);

      // Calculate lunch duration
      Duration lunchDuration = Duration();
      if (lunchInTime != null && lunchOutTime != null) {
        final todayLunchInTime =
            DateTime(now.year, now.month, now.day, lunchInTime!.hour, lunchInTime!.minute);
        final todayLunchOutTime =
            DateTime(now.year, now.month, now.day, lunchOutTime!.hour, lunchOutTime!.minute);
        lunchDuration = todayLunchOutTime.difference(todayLunchInTime);
      }

      // Calculate BRB duration
      Duration brbDuration = Duration();
      if (brbInTime != null && brbOutTime != null) {
        final todayBrbInTime =
            DateTime(now.year, now.month, now.day, brbInTime!.hour, brbInTime!.minute);
        final todayBrbOutTime =
            DateTime(now.year, now.month, now.day, brbOutTime!.hour, brbOutTime!.minute);
        brbDuration = todayBrbOutTime.difference(todayBrbInTime);
      }

      // Calculate end time by adding 8 hours to the start time and subtracting lunch and BRB durations
      final DateTime endTime = todayStartTime
          .add(const Duration(hours: 8))
          .subtract(lunchDuration)
          .subtract(brbDuration);

      // Cancel the previous timer if it exists
      _timer?.cancel();

      // Start a new timer that updates the remaining time every second
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final Duration remainingDuration = endTime.difference(DateTime.now());
        String hours = '${remainingDuration.inHours}';
        String minutes = '${remainingDuration.inMinutes.remainder(60)}'.padLeft(2, '0');
        String seconds = '${remainingDuration.inSeconds.remainder(60)}'.padLeft(2, '0');

        setState(() {
          remainingTimeString = 'Remaining Time: $hours:$minutes:$seconds';
        });

        // Stop the timer when the remaining time is zero or negative
        if (remainingDuration.isNegative) {
          timer.cancel();
          remainingTimeString = 'Time\'s up!';
        }
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('endTimeString', endTimeString);
      await prefs.setString('remainingTimeString', remainingTimeString);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(100.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (endTimeString.isNotEmpty)
            const SizedBox(height: 70.0),
              Text(
                endTimeString,
                style: Theme.of(context).textTheme.headline5?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 20.0),
            Text(
              remainingTimeString,
              style: Theme.of(context).textTheme.subtitle1?.copyWith(
                    color: Colors.white,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 50.0),
            Center(child: buildButton('Start Time', startTime, width: 250, icon: Icons.timer)),
            const SizedBox(height: 10.0),
            Center(child: buildButton('Lunch Out Time', lunchOutTime, width: 250, icon: Icons.restaurant)),
            const SizedBox(height: 10.0),
            Center(child: buildButton('Lunch In Time', lunchInTime, width: 250, icon: Icons.restaurant_menu)),
            const SizedBox(height: 10.0),
            Center(child: buildButton('BRB Out Time', brbOutTime, width: 250, icon: Icons.pause_circle_outline)),
            const SizedBox(height: 10.0),
            Center(child: buildButton('BRB In Time', brbInTime, width: 250, icon: Icons.play_circle_outline)),
            const SizedBox(height: 70.0), // Added extra space before the "Reset All" button
            Center(
              child: ElevatedButton(
                onPressed: _resetAll,
                child: const Text('Reset All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                  minimumSize: const Size(200, 50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildButton(String label, TimeOfDay? time,
      {double width = 300.0, IconData icon = Icons.access_time}) {
    return ElevatedButton.icon(
      onPressed: () => _selectTime(context, label),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        '$label ${time != null ? time.format(context) : ""}',
        style: const TextStyle(color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6B99C2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        minimumSize: Size(width, 50),
      ),
    );
  }
}