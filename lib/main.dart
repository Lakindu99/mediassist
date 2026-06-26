import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Make sure Flutter's engine is ready before we run async setup.
  WidgetsFlutterBinding.ensureInitialized();

  // Connect the app to your Firebase project.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MediAssistApp());
}

class MediAssistApp extends StatelessWidget {
  const MediAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediAssist',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const StartupScreen(),
    );
  }
}

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.health_and_safety, size: 96, color: Colors.teal),
            SizedBox(height: 24),
            Text(
              'MediAssist',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Firebase connected successfully',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}