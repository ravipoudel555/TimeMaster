import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/alarm_controller.dart';
import '../models/alarm_model.dart';

/// View for alarm functionality
class AlarmView extends StatelessWidget {
  const AlarmView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alarms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateAlarmDialog(context),
          ),
        ],
      ),
      body: Consumer<AlarmController>(
        builder: (context, controller, child) {
          final alarms = controller.alarms;

          if (alarms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No alarms yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + to create an alarm',
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
            itemCount: alarms.length,
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              return _AlarmCard(alarm: alarm);
            },
          );
        },
      ),
    );
  }

  void _showCreateAlarmDialog(BuildContext context) {
    final nameController = TextEditingController(text: 'Alarm');
    TimeOfDay selectedTime = TimeOfDay.now();
    Set<int> repeatDays = {};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create Alarm'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Alarm Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (time != null) {
                      setState(() => selectedTime = time);
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text('Repeat'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (index) {
                    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                    final isSelected = repeatDays.contains(index);
                    return FilterChip(
                      label: Text(dayNames[index]),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            repeatDays.add(index);
                          } else {
                            repeatDays.remove(index);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                context.read<AlarmController>().createAlarm(
                      name: nameController.text,
                      time: selectedTime,
                      repeatDays: repeatDays,
                    );
                Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Alarm card widget
class _AlarmCard extends StatelessWidget {
  final AlarmModel alarm;

  const _AlarmCard({required this.alarm});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<AlarmController>();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Switch(
          value: alarm.isActive,
          onChanged: (value) => controller.toggleAlarm(alarm.id),
        ),
        title: Text(
          alarm.name,
          style: TextStyle(
            decoration: alarm.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              alarm.formattedTime,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(alarm.repeatDaysString),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => controller.deleteAlarm(alarm.id),
        ),
        isThreeLine: true,
      ),
    );
  }
}

