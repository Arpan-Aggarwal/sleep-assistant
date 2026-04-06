// lib/screens/support_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/constants.dart';
import 'package:audioplayers/audioplayers.dart';


class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with SingleTickerProviderStateMixin {

  String _currentView = 'menu';
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _currentSound = '';

  // Breathing
  late AnimationController _breatheController;
  late Animation<double>    _breatheAnim;
  String _breatheText  = 'Inhale';
  int    _breatheCount = 4;
  Timer? _breatheTimer;

  // Journal
  final _journalCtrl = TextEditingController();
  final _chatCtrl    = TextEditingController();
  String _chatResponse = '';

  final List<String> _prompts = [
    'What is making it hard to sleep?',
    'What is on your mind right now?',
    'What would make tomorrow feel easier?',
    'What do you need to let go of tonight?',
  ];

  @override
  void initState() {
    super.initState();
    _breatheController = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 4),
    );
    _breatheAnim = Tween<double>(begin: 0.7, end: 1.2).animate(
      CurvedAnimation(
        parent: _breatheController,
        curve:  Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _breatheController.dispose();
    _breatheTimer?.cancel();
    _journalCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.darkNavy),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12,
              ),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _goBack,
                    child: Text(
                      '< back',
                      style: TextStyle(
                        color: Color(AppConstants.lavendorText)
                            .withOpacity(0.6),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _currentView == 'menu'
                          ? 'I am here.'
                          : _viewTitle(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color:      Colors.white,
                        fontSize:   20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 60),
                ],
              ),
            ),

            // ── Content
            Expanded(
              child: _buildCurrentView(),
            ),
          ],
        ),
      ),
    );
  }

  String _viewTitle() {
    switch (_currentView) {
      case 'breathe':  return 'Breathe with this';
      case 'journal':  return 'Write it out';
      case 'sounds':   return 'Calm sounds';
      case 'talk':     return 'I am listening.';
      default:         return 'I am here.';
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'breathe': return _buildBreatheView();
      case 'journal': return _buildJournalView();
      case 'sounds':  return _buildSoundsView();
      case 'talk':    return _buildTalkView();
      default:        return _buildMenuView();
    }
  }

  // ── Menu ────────────────────────────────────────────────

  Widget _buildMenuView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'What would help right now?',
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _menuCard('Breathe',
              '4-7-8 breathing exercise', 'breathe'),
          const SizedBox(height: 16),
          _menuCard('Write it out',
              'One quiet prompt, no pressure', 'journal'),
          const SizedBox(height: 16),
          _menuCard('Calm sounds',
              'Rain, white noise, silence', 'sounds'),
          const SizedBox(height: 16),
          _menuCard('Talk',
              'Type what is on your mind', 'talk'),
        ],
      ),
    );
  }

  Widget _menuCard(String title, String subtitle, String view) {
    return GestureDetector(
      onTap: () => _switchView(view),
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

  // ── Breathe ─────────────────────────────────────────────

  Widget _buildBreatheView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _breatheAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: _breatheAnim.value,
                child: Container(
                  width:  180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(AppConstants.softNavy),
                    boxShadow: [
                      BoxShadow(
                        color: Color(AppConstants.accentBlue)
                            .withOpacity(0.4),
                        blurRadius:   30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _breatheText,
                      style: const TextStyle(
                        color:    Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            '$_breatheCount',
            style: TextStyle(
              color:    Color(AppConstants.lavendorText),
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '4 - 7 - 8  breathing',
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.4),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => _switchView('menu'),
            child: Text(
              'stop',
              style: TextStyle(
                color: Color(AppConstants.lavendorText)
                    .withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startBreatheCycle() {
    _breatheInhale();
  }

  void _breatheInhale() {
    if (!mounted || _currentView != 'breathe') return;
    setState(() {
      _breatheText  = 'Inhale';
      _breatheCount = 4;
    });
    _breatheController.forward(from: 0);
    _countdown(4, _breatheHold);
  }

  void _breatheHold() {
    if (!mounted || _currentView != 'breathe') return;
    setState(() {
      _breatheText  = 'Hold';
      _breatheCount = 7;
    });
    _countdown(7, _breatheExhale);
  }

  void _breatheExhale() {
    if (!mounted || _currentView != 'breathe') return;
    setState(() {
      _breatheText  = 'Exhale';
      _breatheCount = 8;
    });
    _breatheController.reverse();
    _countdown(8, _breatheInhale);
  }

  void _countdown(int seconds, VoidCallback onDone) {
    int remaining = seconds;
    _breatheTimer?.cancel();
    _breatheTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _currentView != 'breathe') {
        t.cancel();
        return;
      }
      remaining--;
      setState(() => _breatheCount = remaining);
      if (remaining <= 0) {
        t.cancel();
        onDone();
      }
    });
  }

  // ── Journal ─────────────────────────────────────────────

  Widget _buildJournalView() {
    final prompt = _prompts[
        DateTime.now().millisecond % _prompts.length
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            prompt,
            style: TextStyle(
              color:    Color(AppConstants.lavendorText),
              fontSize: 15,
              height:   1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: TextField(
              controller: _journalCtrl,
              maxLines:   null,
              expands:    true,
              style: const TextStyle(
                color:   Colors.white,
                height:  1.6,
              ),
              decoration: InputDecoration(
                hintText:  'Just write... no one will judge this.',
                hintStyle: TextStyle(
                  color: Color(AppConstants.lavendorText)
                      .withOpacity(0.3),
                ),
                filled:    true,
                fillColor: Color(AppConstants.softNavy),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:   BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home_night');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConstants.accentBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'done',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sounds ──────────────────────────────────────────────

  Widget _buildSoundsView() {
  final sounds = [
    {'name': 'Rain',        'file': 'audio/rain.mp3'},
    {'name': 'White noise', 'file': 'audio/white_noise.mp3'},
    {'name': 'Deep silence', 'file': 'audio/sleep_music.mp3'},
  ];

  return Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      children: [
        Text(
          'Tap to play. Tap again to stop.',
          style: TextStyle(
            color:    Color(AppConstants.lavendorText)
                .withOpacity(0.4),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 24),
        ...sounds.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: SizedBox(
            width:  double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () => _toggleSound(
                s['file'] as String?,
                s['name'] as String,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentSound == s['name']
                    ? Color(AppConstants.accentBlue)
                    : Color(AppConstants.softNavy),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _currentSound == s['name']
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white70,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s['name'] as String,
                    style: const TextStyle(
                      color:    Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )),
      ],
    ),
  );
}

Future<void> _toggleSound(String? file, String name) async {
  // Tapping same sound stops it
  if (_currentSound == name) {
    await _audioPlayer.stop();
    setState(() => _currentSound = '');
    return;
  }

  // Deep silence — just stop any playing sound
  if (file == null) {
    await _audioPlayer.stop();
    setState(() => _currentSound = 'Deep silence');
    return;
  }

  // Play the selected sound on loop
  await _audioPlayer.stop();
  await _audioPlayer.setReleaseMode(ReleaseMode.loop);
  await _audioPlayer.play(AssetSource(file));
  setState(() => _currentSound = name);
}

  // ── Talk ────────────────────────────────────────────────

  Widget _buildTalkView() {
    final responses = [
      'That makes sense. You are not alone in feeling this.',
      'Thank you for sharing that. Rest when you can.',
      'It is okay to feel this way. Tomorrow is a new start.',
      'I hear you. Try to breathe slowly for a moment.',
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Container(
              width:   double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color:        Color(AppConstants.softNavy),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _chatResponse.isEmpty
                    ? 'Type what is on your mind.\nNo judgment here.'
                    : _chatResponse,
                style: TextStyle(
                  color:    Color(AppConstants.lavendorText),
                  fontSize: 14,
                  height:   1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _chatCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:  'What is on your mind...',
                    hintStyle: TextStyle(
                      color: Color(AppConstants.lavendorText)
                          .withOpacity(0.3),
                    ),
                    filled:    true,
                    fillColor: Color(AppConstants.softNavy),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:   BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_chatCtrl.text.trim().isEmpty) return;
                  final response = responses[
                      DateTime.now().millisecond % responses.length
                  ];
                  setState(() {
                    _chatResponse =
                        'You: ${_chatCtrl.text.trim()}\n\n$response';
                    _chatCtrl.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.accentBlue),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'send',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Navigation ──────────────────────────────────────────

  void _switchView(String view) {
    _breatheTimer?.cancel();
    _breatheController.stop();
    setState(() => _currentView = view);

    if (view == 'breathe') {
      Future.delayed(
        const Duration(milliseconds: 300),
        _startBreatheCycle,
      );
    }
  }

  void _goBack() async{
    _breatheTimer?.cancel();
    _breatheController.stop();
    await _audioPlayer.stop();

    if (_currentView != 'menu') {
      setState(() => _currentView = 'menu');
    } else {
      Navigator.pushReplacementNamed(context, '/home_night');
    }
  }
}
