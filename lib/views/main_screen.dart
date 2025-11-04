import 'package:flutter/material.dart';
import 'clock_view.dart';
import 'timer_view.dart';
import 'alarm_view.dart';
import 'stopwatch_view.dart';

/// Main screen with bottom navigation
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ClockView(),
    const TimerView(),
    const AlarmView(),
    const StopwatchView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.access_time),
            label: 'Clock',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer),
            label: 'Timer',
          ),
          NavigationDestination(
            icon: Icon(Icons.alarm),
            label: 'Alarm',
          ),
          NavigationDestination(
            icon: Icon(Icons.timer_outlined),
            label: 'Stopwatch',
          ),
        ],
      ),
    );
  }
}

