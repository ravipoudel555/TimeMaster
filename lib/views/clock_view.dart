import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// View for displaying the current time (clock)
class ClockView extends StatefulWidget {
  const ClockView({super.key});

  @override
  State<ClockView> createState() => _ClockViewState();
}

class _ClockViewState extends State<ClockView> {
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    setState(() {
      _currentTime = DateTime.now();
    });
    Future.delayed(const Duration(seconds: 1), _updateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clock'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Digital clock
            Text(
              DateFormat('HH:mm:ss').format(_currentTime),
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Date
            Text(
              DateFormat('EEEE, MMMM d, yyyy').format(_currentTime),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            // 12-hour format
            Text(
              DateFormat('h:mm:ss a').format(_currentTime),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

