// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {

  int    _step      = 1;
  bool   _isSignIn  = false;
  bool   _loading   = false;
  String _error     = '';

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _input1Ctrl   = TextEditingController();

  String _userId    = '';
  String _sleepTime = '';

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _input1Ctrl.dispose();
    super.dispose();
  }

  // ── UI ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.darkNavy),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildStepLabel(),
              const SizedBox(height: 30),
              _buildQuestion(),
              const SizedBox(height: 10),
              _buildSubtitle(),
              const SizedBox(height: 40),
              _buildInputs(),
              const SizedBox(height: 16),
              if (_error.isNotEmpty) _buildError(),
              const SizedBox(height: 16),
              _buildPrimaryButton(),
              const SizedBox(height: 16),
              if (_step == 1) _buildToggleButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepLabel() {
    String text = _isSignIn
        ? 'Welcome back'
        : _step == 1 ? 'New here' : 'Step $_step of 4';
    return Text(
      text,
      style: TextStyle(
        color: Color(AppConstants.lavendorText).withOpacity(0.6),
        fontSize: 13,
      ),
    );
  }

  Widget _buildQuestion() {
    final questions = {
      'signup': 'Create your account',
      'signin': 'Sign In',
      2:        'When do you want to sleep?',
      3:        'When do you wake up?',
      4:        'How should I check in with you?',
    };
    final key = _step == 1 ? (_isSignIn ? 'signin' : 'signup') : _step;
    return Text(
      questions[key] ?? '',
      style: const TextStyle(
        color:      Colors.white,
        fontSize:   26,
        fontWeight: FontWeight.bold,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    final subtitles = {
      'signup': 'Your data stays private and secure',
      'signin': 'Good to see you again',
      2:        'We start watching over you from this time',
      3:        'Your morning report will be ready by then',
      4:        'You can change this later',
    };
    final key = _step == 1 ? (_isSignIn ? 'signin' : 'signup') : _step;
    return Text(
      subtitles[key] ?? '',
      style: TextStyle(
        color:    Color(AppConstants.lavendorText).withOpacity(0.6),
        fontSize: 13,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildInputs() {
    if (_step == 4) return _buildModeButtons();

    if (_step == 1) {
      return Column(
        children: [
          _buildTextField(
            controller: _emailCtrl,
            hint:       'Email address',
            keyboard:   TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordCtrl,
            hint:       'Password (min 6 characters)',
            obscure:    true,
          ),
        ],
      );
    }

    return _buildTextField(
      controller: _input1Ctrl,
      hint: _step == 2 ? 'e.g. 11:00 PM' : 'e.g. 6:30 AM',
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscure              = false,
    TextInputType keyboard    = TextInputType.text,
  }) {
    return TextField(
      controller:    controller,
      obscureText:   obscure,
      keyboardType:  keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText:      hint,
        hintStyle: TextStyle(
          color: Color(AppConstants.lavendorText).withOpacity(0.5),
        ),
        filled:      true,
        fillColor:   Color(AppConstants.softNavy),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:   BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 16,
        ),
      ),
    );
  }

  Widget _buildModeButtons() {
    return Column(
      children: [
        _modeCard(
          title:    'Silent Mode',
          subtitle: 'Only a soft notification if needed',
          mode:     'silent',
        ),
        const SizedBox(height: 16),
        _modeCard(
          title:    'Active Mode',
          subtitle: 'Offer support tools more often',
          mode:     'active',
        ),
      ],
    );
  }

  Widget _modeCard({
    required String title,
    required String subtitle,
    required String mode,
  }) {
    return GestureDetector(
      onTap: () => _selectMode(mode),
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        Color(AppConstants.softNavy),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color:    Color(AppConstants.lavendorText),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Text(
      _error,
      style: const TextStyle(color: Colors.redAccent, fontSize: 13),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildPrimaryButton() {
    if (_step == 4) return const SizedBox.shrink();

    String label = _step == 1
        ? (_isSignIn ? 'Sign In' : 'Create Account')
        : 'Continue';

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _onNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(AppConstants.accentBlue),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(
                label,
                style: const TextStyle(
                  fontSize:   16,
                  fontWeight: FontWeight.w600,
                  color:      Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _isSignIn = !_isSignIn;
          _error    = '';
          _emailCtrl.clear();
          _passwordCtrl.clear();
        });
      },
      child: Text(
        _isSignIn
            ? 'New here?  Create an Account'
            : 'Already have an account?  Sign In',
        style: TextStyle(
          color:    Color(AppConstants.accentBlue),
          fontSize: 13,
        ),
      ),
    );
  }

  // ── Logic ────────────────────────────────────────────────

  void _onNext() {
    setState(() => _error = '');

    if (_step == 1) {
      _isSignIn ? _handleSignIn() : _handleSignUp();
    } else if (_step == 2) {
      _handleStep2();
    } else if (_step == 3) {
      _handleStep3();
    }
  }

  Future<void> _handleSignUp() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in both fields');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService.signUp(
      email: email, password: password,
    );
    setState(() => _loading = false);

    if (result['success']) {
      _userId = result['user_id'];
      _goToStep(2);
    } else {
      setState(() => _error = result['error']);
    }
  }

  Future<void> _handleSignIn() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please fill in both fields');
      return;
    }

    setState(() => _loading = true);
    final result = await AuthService.signIn(
      email: email, password: password,
    );
    setState(() => _loading = false);

    if (result['success']) {
      _userId = result['user_id'];
      await StorageService.updatePref('setup_complete', true);
      _goHome();
    } else {
      setState(() => _error = result['error']);
    }
  }

  void _handleStep2() {
    final sleepTime = _input1Ctrl.text.trim();
    if (sleepTime.isEmpty) {
      setState(() => _error = 'Please enter a time e.g. 11:00 PM');
      return;
    }
    _sleepTime = sleepTime;
    _input1Ctrl.clear();
    _goToStep(3);
  }

  void _handleStep3() {
    final wakeTime = _input1Ctrl.text.trim();
    if (wakeTime.isEmpty) {
      setState(() => _error = 'Please enter a time e.g. 6:30 AM');
      return;
    }
    _goToStep(4);
  }

  void _selectMode(String mode) async {
    final prefs = await StorageService.getPrefs();
    prefs['sleepGoalTime']  = _sleepTime;
    prefs['mode']           = mode;
    prefs['user_id']        = _userId;
    prefs['setup_complete'] = true;
    await StorageService.savePrefs(prefs);

    await ApiService.saveProfile(
      userId:  _userId,
      profile: prefs,
    );

    _goHome();
  }

  void _goToStep(int step) {
    setState(() {
      _step  = step;
      _error = '';
      _input1Ctrl.clear();
    });
  }

  void _goHome() {
    final hour    = DateTime.now().hour;
    final isNight = hour >= AppConstants.nightStart ||
                    hour < AppConstants.nightEnd;
    Navigator.pushReplacementNamed(
      context,
      isNight ? '/home_night' : '/home_day',
    );
  }
}