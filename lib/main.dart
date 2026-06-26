import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/services/auth_service.dart';
import 'features/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MediAssistApp());
}

class MediAssistApp extends StatelessWidget {
  const MediAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Provider makes AuthService available to every screen.
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'MediAssist',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const AuthGate(),
      ),
    );
  }
}
