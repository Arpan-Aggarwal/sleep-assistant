// lib/main.dart
import 'firebase_options.dart';
import 'services/background.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_night_screen.dart';
import 'screens/home_day_screen.dart';
import 'screens/support_screen.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[App] Firebase OK');
  } catch (e) {
    print('[App] Firebase failed: $e');
  }

  try {
    await BackgroundServiceManager.initialize();
    print('[App] Background service OK');
  } catch (e) {
    print('[App] Background service failed: $e');
  }

  runApp(const SleepAssistantApp());
}

class SleepAssistantApp extends StatelessWidget {
  const SleepAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sleep Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.dark(
          background: Color(AppConstants.darkNavy),
          primary:    Color(AppConstants.accentBlue),
        ),
        scaffoldBackgroundColor: Color(AppConstants.darkNavy),
        fontFamily: 'Roboto',
      ),
      routes: {
        '/':           (context) => const StartupScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home_night': (context) => const HomeNightScreen(),
        '/home_day':   (context) => const HomeDayScreen(),
        '/support':    (context) => const SupportScreen(),
      },
      initialRoute: '/',
    );
  }
}

// ── Startup screen decides where to go ───────────────────────
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 500));

    final setupComplete = await StorageService.isSetupComplete();

    if (!setupComplete) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final hour = DateTime.now().hour;
    final isNight = hour >= AppConstants.nightStart ||
                    hour < AppConstants.nightEnd;

    if (isNight) {
      Navigator.pushReplacementNamed(context, '/home_night');
    } else {
      Navigator.pushReplacementNamed(context, '/home_day');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7B8FBF),
        ),
      ),
    );
  }
}