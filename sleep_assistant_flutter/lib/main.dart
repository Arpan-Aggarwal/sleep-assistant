import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_night_screen.dart';
import 'screens/home_day_screen.dart';
import 'screens/support_screen.dart';
import 'services/storage_service.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SleepAssistantApp());
}

class SleepAssistantApp extends StatelessWidget {
  const SleepAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title:                      'Sleep Assistant',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Color(AppConstants.darkNavy),
        colorScheme: ColorScheme.dark(
          background: Color(AppConstants.darkNavy),
          primary:    Color(AppConstants.accentBlue),
        ),
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
    await Future.delayed(const Duration(milliseconds: 300));

    final setupComplete = await StorageService.isSetupComplete();

    if (!mounted) return;

    if (!setupComplete) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    final hour    = DateTime.now().hour;
    final isNight = hour >= AppConstants.nightStart ||
                    hour < AppConstants.nightEnd;

    Navigator.pushReplacementNamed(
      context,
      isNight ? '/home_night' : '/home_day',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.darkNavy),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sleep Assistant',
              style: TextStyle(
                color:    Color(AppConstants.lavendorText),
                fontSize: 24,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              color: Color(AppConstants.lavendorText),
            ),
          ],
        ),
      ),
    );
  }
}