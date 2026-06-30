import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/settings_provider.dart';
import 'core/services/adaptive_provider.dart';
import 'core/services/behaviour_tracker.dart';
import 'features/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  final settings = SettingsProvider();
  await settings.load();
  final adaptive = AdaptiveProvider();
  await adaptive.load();

  runApp(MediAssistApp(settings: settings, adaptive: adaptive));
}

class MediAssistApp extends StatefulWidget {
  final SettingsProvider settings;
  final AdaptiveProvider adaptive;
  const MediAssistApp({super.key, required this.settings, required this.adaptive});

  @override
  State<MediAssistApp> createState() => _MediAssistAppState();
}

class _MediAssistAppState extends State<MediAssistApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Save the behaviour session when the app goes to the background.
    if (state == AppLifecycleState.paused) {
      BehaviourTracker.instance.persist();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider<SettingsProvider>.value(value: widget.settings),
        ChangeNotifierProvider<AdaptiveProvider>.value(value: widget.adaptive),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, s, _) {
          return MaterialApp(
            title: 'MediAssist',
            debugShowCheckedModeBanner: false,
            navigatorObservers: [BehaviourNavigatorObserver()],
            theme: s.highContrast ? _highContrastTheme() : _normalTheme(),
            builder: (context, child) {
              // Global tap listener: passively records every tap for the tracker
              // (does not consume the event, so buttons still work normally).
              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) => BehaviourTracker.instance.logTap(e.position),
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(s.fontScale)),
                  child: child!,
                ),
              );
            },
            home: const AuthGate(),
          );
        },
      ),
    );
  }

  ThemeData _normalTheme() =>
      ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true);

  ThemeData _highContrastTheme() {
    final scheme = ColorScheme.fromSeed(
      seedColor: Colors.black,
      brightness: Brightness.light,
    ).copyWith(
      primary: Colors.black,
      onPrimary: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,
    );
  }
}
