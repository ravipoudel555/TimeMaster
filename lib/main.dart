import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'controllers/timer_controller.dart';
import 'controllers/alarm_controller.dart';
import 'controllers/stopwatch_controller.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'services/background_service.dart';
import 'views/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz.initializeTimeZones();
  // Use system's local timezone
  try {
    final locationName = tz.local.name;
    tz.setLocalLocation(tz.getLocation(locationName));
  } catch (e) {
    // Fallback to UTC if location detection fails
    tz.setLocalLocation(tz.UTC);
  }

  // Initialize notification service
  await NotificationService().initialize();

  // Initialize background service
  await BackgroundService().initialize();

  // Load controllers and initialize data
  final timerController = TimerController();
  final alarmController = AlarmController();
  final stopwatchController = StopwatchController();

  await timerController.loadTimers();
  await alarmController.loadAlarms();
  await stopwatchController.loadStopwatches();

  // Start background task
  await BackgroundService().startBackgroundTask();

  // Load theme preference
  final storage = StorageService();
  final themeModeString = await storage.loadThemeMode();
  ThemeMode themeMode = ThemeMode.system;
  if (themeModeString == 'light') {
    themeMode = ThemeMode.light;
  } else if (themeModeString == 'dark') {
    themeMode = ThemeMode.dark;
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: timerController),
        ChangeNotifierProvider.value(value: alarmController),
        ChangeNotifierProvider.value(value: stopwatchController),
      ],
      child: MyApp(initialThemeMode: themeMode),
    ),
  );
}

class MyApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MyApp({super.key, required this.initialThemeMode});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeMode _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timer App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: MainScreenWrapper(
        onThemeChanged: (mode) {
          setState(() {
            _themeMode = mode;
          });
        },
      ),
    );
  }
}

/// Wrapper for MainScreen to pass theme toggle callback
class MainScreenWrapper extends StatelessWidget {
  final ValueChanged<ThemeMode> onThemeChanged;

  const MainScreenWrapper({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const MainScreen(),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),

        child: FloatingActionButton(
          onPressed: () {
            // Show theme selection dialog
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Theme'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.light_mode),
                      title: const Text('Light'),
                      onTap: () {
                        Navigator.pop(context);
                        onThemeChanged(ThemeMode.light);
                        StorageService().saveThemeMode('light');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.dark_mode),
                      title: const Text('Dark'),
                      onTap: () {
                        Navigator.pop(context);
                        onThemeChanged(ThemeMode.dark);
                        StorageService().saveThemeMode('dark');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.brightness_auto),
                      title: const Text('System'),
                      onTap: () {
                        Navigator.pop(context);
                        onThemeChanged(ThemeMode.system);
                        StorageService().saveThemeMode('system');
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          child: const Icon(Icons.palette),
        ),
      ),
    );
  }
}
