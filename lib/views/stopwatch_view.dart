import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/stopwatch_controller.dart';
import '../models/stopwatch_model.dart';

/// View for stopwatch functionality
class StopwatchView extends StatelessWidget {
  const StopwatchView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stopwatch'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.read<StopwatchController>().createStopwatch(),
          ),
        ],
      ),
      body: Consumer<StopwatchController>(
        builder: (context, controller, child) {
          final stopwatches = controller.stopwatches;

          if (stopwatches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No stopwatches yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create a stopwatch',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stopwatches.length,
            itemBuilder: (context, index) {
              final stopwatch = stopwatches[index];
              return _StopwatchCard(stopwatch: stopwatch);
            },
          );
        },
      ),
    );
  }
}

/// Stopwatch card widget
class _StopwatchCard extends StatelessWidget {
  final StopwatchModel stopwatch;

  const _StopwatchCard({required this.stopwatch});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<StopwatchController>();
    final isRunning = stopwatch.status == StopwatchStatus.running;
    final isPaused = stopwatch.status == StopwatchStatus.paused;

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
                Text(
                  stopwatch.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => controller.deleteStopwatch(stopwatch.id),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                stopwatch.formattedTime,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (isRunning)
                  ElevatedButton.icon(
                    onPressed: () => controller.pauseStopwatch(stopwatch.id),
                    icon: const Icon(Icons.pause),
                    label: const Text('Pause'),
                  )
                else if (isPaused)
                  ElevatedButton.icon(
                    onPressed: () => controller.startStopwatch(stopwatch.id),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Resume'),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => controller.startStopwatch(stopwatch.id),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                if (isRunning)
                  ElevatedButton.icon(
                    onPressed: () => controller.addLap(stopwatch.id),
                    icon: const Icon(Icons.flag),
                    label: const Text('Lap'),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: () => controller.resetStopwatch(stopwatch.id),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reset'),
                  ),
              ],
            ),
            if (stopwatch.laps.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Laps',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...stopwatch.laps.asMap().entries.map((entry) {
                final index = entry.key;
                final lap = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Lap ${index + 1}'),
                      Row(
                        children: [
                          Text(
                            lap.formattedLapTime,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            lap.formattedTotalTime,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }
}

