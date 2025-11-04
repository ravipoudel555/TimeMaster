import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../controllers/timer_controller.dart';
import '../models/timer_model.dart';

/// View for countdown timer functionality
class TimerView extends StatelessWidget {
  const TimerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Timers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTimerDialog(context),
          ),
        ],
      ),
      body: Consumer<TimerController>(
        builder: (context, controller, child) {
          final timers = controller.timers;

          if (timers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No timers yet',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create a timer',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: timers.length,
            itemBuilder: (context, index) {
              final timer = timers[index];
              return _TimerCard(timer: timer);
            },
          );
        },
      ),
    );
  }

  void _showCreateTimerDialog(BuildContext context) {
    final nameController = TextEditingController(text: 'Timer');
    Duration selectedDuration = Duration.zero;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Create Timer',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Timer Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                'Hours',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Minutes',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Seconds',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: selectedDuration.inHours,
                                ),
                                itemExtent: 40,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    selectedDuration = Duration(
                                      hours: value,
                                      minutes: selectedDuration.inMinutes
                                          .remainder(60),
                                      seconds: selectedDuration.inSeconds
                                          .remainder(60),
                                    );
                                  });
                                },
                                children: List.generate(24, (index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: selectedDuration.inMinutes
                                      .remainder(60),
                                ),
                                itemExtent: 40,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    selectedDuration = Duration(
                                      hours: selectedDuration.inHours,
                                      minutes: value,
                                      seconds: selectedDuration.inSeconds
                                          .remainder(60),
                                    );
                                  });
                                },
                                children: List.generate(60, (index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Expanded(
                              child: CupertinoPicker(
                                scrollController: FixedExtentScrollController(
                                  initialItem: selectedDuration.inSeconds
                                      .remainder(60),
                                ),
                                itemExtent: 40,
                                onSelectedItemChanged: (int value) {
                                  setState(() {
                                    selectedDuration = Duration(
                                      hours: selectedDuration.inHours,
                                      minutes: selectedDuration.inMinutes
                                          .remainder(60),
                                      seconds: value,
                                    );
                                  });
                                },
                                children: List.generate(60, (index) {
                                  return Center(
                                    child: Text(
                                      index.toString().padLeft(2, '0'),
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          if (selectedDuration.inSeconds > 0) {
                            context.read<TimerController>().createTimer(
                              name: nameController.text,
                              duration: selectedDuration,
                            );
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Create'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Timer card widget
class _TimerCard extends StatelessWidget {
  final TimerModel timer;

  const _TimerCard({required this.timer});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<TimerController>();
    final isRunning = timer.status == TimerStatus.running;
    final isPaused = timer.status == TimerStatus.paused;
    final isFinished = timer.status == TimerStatus.finished;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(timer.name, style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.cancelTimer(timer.id),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                timer.formattedTime,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isFinished ? Colors.red : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isRunning)
                  ElevatedButton.icon(
                    onPressed: () => controller.pauseTimer(timer.id),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  )
                else if (isPaused)
                  ElevatedButton.icon(
                    onPressed: () => controller.startTimer(timer.id),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => controller.startTimer(timer.id),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                OutlinedButton.icon(
                  onPressed: () => controller.resetTimer(timer.id),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
