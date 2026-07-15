import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/settings_provider.dart';
import 'core/services/adaptive_provider.dart';
import 'core/services/adaptive_engine.dart';
import 'core/services/behaviour_tracker.dart';
import 'core/theme/app_theme.dart';
import 'features/onboarding/root_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();

  final settings = SettingsProvider();
  await settings.load();

  final engine = AdaptiveEngine();
  final adaptive = AdaptiveProvider(engine: engine);
  await adaptive.load();

  BehaviourTracker.instance.onMetricsChanged = engine.evaluate;

  runApp(MediAssistApp(settings: settings, adaptive: adaptive, engine: engine));
}

class MediAssistApp extends StatefulWidget {
  final SettingsProvider settings;
  final AdaptiveProvider adaptive;
  final AdaptiveEngine engine;
  const MediAssistApp({
    super.key,
    required this.settings,
    required this.adaptive,
    required this.engine,
  });

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
        ChangeNotifierProvider<AdaptiveEngine>.value(value: widget.engine),
      ],
      child: Consumer3<SettingsProvider, AdaptiveProvider, AdaptiveEngine>(
        builder: (context, s, adaptive, engine, _) {
          final adaptiveOn = adaptive.adaptiveMode;
          final fontScale =
              adaptiveOn ? math.max(s.fontScale, engine.fontScale) : s.fontScale;
          final highContrast =
              s.highContrast || (adaptiveOn && engine.forceHighContrast);

          return MaterialApp(
            title: 'MediAssist',
            debugShowCheckedModeBanner: false,
            navigatorObservers: [BehaviourNavigatorObserver()],
            theme: highContrast ? buildHighContrastTheme() : buildAppTheme(),
            builder: (context, child) {
              return Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (e) => BehaviourTracker.instance.logTap(e.position),
                child: MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(fontScale)),
                  child: child!,
                ),
              );
            },
            home: const RootGate(),
          );
        },
      ),
    );
  }
}
