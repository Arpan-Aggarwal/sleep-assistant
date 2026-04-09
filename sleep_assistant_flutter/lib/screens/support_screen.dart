// lib/screens/support_screen.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen>
    with TickerProviderStateMixin {

  // ── State ────────────────────────────────────────────────
  String _currentView = 'level_select';

  // ── Audio ────────────────────────────────────────────────
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool   _isPlaying    = false;
  String _currentSound = '';

  // ── Level 1 sounds ───────────────────────────────────────
  final List<Map<String, String>> _level1Sounds = [
    {'name': 'Rain',        'file': 'audio/rain.mp3'},
    {'name': 'Etherial Light', 'file': 'audio/etherial_light.mp3'},
    {'name': 'Piano', 'file': 'audio/piano.mp3'},
  ];
  int _level1SoundIndex = 0;

  // ── Wave animation ───────────────────────────────────────
  late AnimationController _waveController;
  late Animation<double>   _waveAnim;

  // ── Breathing ────────────────────────────────────────────
  late AnimationController _breatheController;
  late Animation<double>   _breatheAnim;
  String _breathePhase  = 'Inhale';
  int    _breatheCount  = 4;
  int    _breatheCycle  = 0;
  Timer? _breatheTimer;
  String _motivationLine = '';
  static const int _totalBreatheCycles = 5;
  bool _level2AutoTransitioned = false;

  // ── Blink Exercise ───────────────────────────────────────
  int    _blinkSeconds = 30;
  bool   _blinkDone    = false;
  Timer? _blinkTimer;

  // ── Ball Game (hide and seek) ─────────────────────────────
  int    _ballRound       = 0;
  bool   _ballVisible     = true;
  double _ballX           = 0.5;
  double _ballY           = 0.5;
  Timer? _ballTimer;
  String _ballInstruction = 'Look at the star';

  // ── Ball Follow Game ─────────────────────────────────────
  double _followX           = 0.5;
  double _followY           = 0.5;
  bool   _followVisible     = true;
  Timer? _followTimer;
  String _followInstruction = 'Follow the star with your eyes';
  Offset _followVelocity    = const Offset(0.004, 0.003);

  // ── Yoga Nidra ───────────────────────────────────────────
  int    _yogaStep  = 0;
  Timer? _yogaTimer;

  // ── Journal ──────────────────────────────────────────────
  final _journalCtrl = TextEditingController();

  // ── Level 3 tab ──────────────────────────────────────────
  int _level3Tab = 0;

  // ── Random ───────────────────────────────────────────────
  final Random _random = Random();

  // ── Extended Affirmations ────────────────────────────────
  final List<String> _inhaleAffirmations = [
    'I am calm',
    'I am safe',
    'I am at peace',
    'I am letting go',
    'I am relaxed',
    'I am enough',
    'I am present',
    'I am still',
    'I am grounded',
    'I am healing',
    'I am gentle with myself',
    'I am worthy of rest',
    'I am breathing deeply',
    'I am here right now',
    'I am soft and open',
    'I am free',
    'I am whole',
    'I am light',
    'I am loved',
    'I am home',
  ];

  final List<String> _exhaleAffirmations = [
    'I release all tension',
    'I let go of today',
    'I surrender to rest',
    'I am free from worry',
    'I breathe out stress',
    'I welcome stillness',
    'I drift into sleep',
    'I release what I cannot control',
    'I let go of every thought',
    'I melt into this moment',
    'I release the weight of the day',
    'I let my mind grow quiet',
    'I choose peace over worry',
    'I allow rest to come',
    'I trust tomorrow will be okay',
    'I let go of needing to think',
    'I release all that is not mine',
    'I soften with every breath',
    'I sink deeper into calm',
    'I welcome the darkness gently',
  ];

  // ── Yoga Nidra Steps ─────────────────────────────────────
  final List<Map<String, String>> _yogaSteps = [
    {
      'title': '🛏️  Lie down',
      'instruction':
          'Find a comfortable position on your back.\n\n'
          'Let your arms rest away from your body,\n'
          'palms facing the ceiling.\n\n'
          'Let your feet fall open naturally.\n\n'
          'Close your eyes.\n\n'
          'You have nowhere to be right now.',
    },
    {
      'title': '🌱  Set your intention',
      'instruction':
          'Silently say to yourself, just once:\n\n'
          '"I will sleep deeply tonight.\n'
          'I will wake up feeling rested."\n\n'
          'Do not repeat it.\n'
          'Just let it land gently inside you\n'
          'like a seed in soft ground.',
    },
    {
      'title': '👁️  Right side of body',
      'instruction':
          'Move your attention slowly...\n\n'
          'Right thumb → fingers → palm → wrist\n\n'
          'Forearm → elbow → upper arm → shoulder\n\n'
          'Right chest → right side of belly\n\n'
          'Right thigh → knee → calf → ankle\n\n'
          'Heel → sole → big toe → all toes\n\n'
          'Feel each part, then let it go.',
    },
    {
      'title': '👁️  Left side of body',
      'instruction':
          'Now the left side...\n\n'
          'Left thumb → fingers → palm → wrist\n\n'
          'Forearm → elbow → upper arm → shoulder\n\n'
          'Left chest → left side of belly\n\n'
          'Left thigh → knee → calf → ankle\n\n'
          'Heel → sole → big toe → all toes\n\n'
          'Your body is becoming very heavy.',
    },
    {
      'title': '🧘  Back and face',
      'instruction':
          'Shoulder blades → whole back → spine\n\n'
          'Both buttocks → lower back\n\n'
          'Now your face...\n\n'
          'Forehead → eyebrows → space between them\n\n'
          'Eyes → nose → cheeks → lips → chin\n\n'
          'Let your jaw be completely loose.\n\n'
          'Your whole body is heavy and warm.',
    },
    {
      'title': '🌊  Watch your breath',
      'instruction':
          'Do not change your breathing.\n\n'
          'Just notice it.\n\n'
          'Feel the air entering... cool.\n'
          'Feel the air leaving... warm.\n\n'
          'Count each exhale silently.\n'
          'Start at 27 and count down.\n\n'
          'If you lose count,\n'
          'simply begin at 27 again.\n\n'
          'This is the only thing you need to do.',
    },
    {
      'title': '🌙  A quiet picture',
      'instruction':
          'Picture a still lake at night.\n\n'
          'The water is perfectly flat like a mirror.\n'
          'Stars reflect on its surface.\n\n'
          'You are lying on soft grass nearby.\n'
          'The air is cool and smells like rain.\n\n'
          'You hear nothing except gentle water.\n\n'
          'You are completely safe.\n'
          'Let yourself sink into the ground.',
    },
    {
      'title': '✨  Let sleep come',
      'instruction':
          'Bring awareness back to your whole body.\n\n'
          'Feel it heavy and warm.\n'
          'Feel your breath, slow and easy.\n\n'
          'You have done everything you need to do.\n\n'
          'Now let go of even this practice.\n\n'
          'Let your mind drift wherever it wants.\n\n'
          'Sleep is already on its way to you.\n\n'
          'Just stay here.\n'
          'That is enough.',
    },
  ];

  @override
  void initState() {
    super.initState();

    // Wave animation for level 1
    _waveController = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _waveAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _waveController,
        curve:  Curves.easeInOut,
      ),
    );

    // Breathing animation
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
    _setRandomAffirmation(isInhale: true);
  }

  void _setRandomAffirmation({required bool isInhale}) {
    final list = isInhale
        ? _inhaleAffirmations
        : _exhaleAffirmations;
    setState(() {
      _motivationLine = list[_random.nextInt(list.length)];
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _breatheController.dispose();
    _breatheTimer?.cancel();
    _blinkTimer?.cancel();
    _ballTimer?.cancel();
    _followTimer?.cancel();
    _yogaTimer?.cancel();
    _audioPlayer.dispose();
    _journalCtrl.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.darkNavy),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: _buildCurrentView()),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 8,
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
              _getTitle(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color:      Colors.white,
                fontSize:   18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentView) {
      case 'level_select':   return 'I am here.';
      case 'level1':         return 'Ease into sleep';
      case 'level2_breathe': return 'Breathe with this';
      case 'level2_sounds':  return 'Calm sounds';
      case 'level2_journal': return 'Write it out';
      case 'level3':         return 'Let\'s tire your mind';
      default:               return 'I am here.';
    }
  }

  // ── Current View ─────────────────────────────────────────

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'level_select':   return _buildLevelSelect();
      case 'level1':         return _buildLevel1();
      case 'level2_breathe': return _buildLevel2Breathe();
      case 'level2_sounds':  return _buildLevel2Sounds();
      case 'level2_journal': return _buildJournalView();
      case 'level3':         return _buildLevel3();
      default:               return _buildLevelSelect();
    }
  }

  // ── Level Selection ──────────────────────────────────────

  Widget _buildLevelSelect() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'How are you feeling right now?',
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.6),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _levelCard(
            emoji:    '😴',
            title:    'Drowsy',
            subtitle: 'Drifting toward sleep, just a gentle push away.',
            onTap:    _enterLevel1,
          ),
          const SizedBox(height: 16),
          _levelCard(
            emoji:    '😐',
            title:    'Groggy',
            subtitle: 'Suspended between dreams and daylight.',
            onTap:    _enterLevel2,
          ),
          const SizedBox(height: 16),
          _levelCard(
            emoji:    '😶',
            title:    'Restless',
            subtitle: 'Tossing in wakefulness, craving rest.',
            onTap:    _enterLevel3,
          ),
        ],
      ),
    );
  }

  Widget _levelCard({
    required String       emoji,
    required String       title,
    required String       subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:   double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        Color(AppConstants.softNavy),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color:      Colors.white,
                      fontSize:   16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color:    Color(AppConstants.lavendorText),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Color(AppConstants.lavendorText)
                  .withOpacity(0.4),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // LEVEL 1 — Drowsy
  // ─────────────────────────────────────────────────────────

  void _enterLevel1() {
    _level1SoundIndex = 0;
    setState(() => _currentView = 'level1');
    _playSound(
      _level1Sounds[0]['file']!,
      _level1Sounds[0]['name']!,
    );
  }

  Widget _buildLevel1() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _level1Sounds[_level1SoundIndex]['name']!,
            style: TextStyle(
              color:      Color(AppConstants.lightText),
              fontSize:   22,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let it carry you to sleep.',
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.5),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 40),

          // Fixed wave animation
          _buildSoundWave(),

          const SizedBox(height: 40),

          // Play / Pause
          GestureDetector(
            onTap: _toggleAudio,
            child: Container(
              width:  70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(AppConstants.softNavy),
                boxShadow: [
                  BoxShadow(
                    color: Color(AppConstants.accentBlue)
                        .withOpacity(0.25),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: Icon(
                _isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                color: Color(AppConstants.lavendorText),
                size:  32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _isPlaying ? 'playing' : 'paused',
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 36),

          // Sound switcher pills
          Text(
            'Switch sound',
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.4),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _level1Sounds.asMap().entries.map((e) {
              final idx      = e.key;
              final sound    = e.value;
              final selected = idx == _level1SoundIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _level1SoundIndex = idx);
                  _playSound(sound['file']!, sound['name']!);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Color(AppConstants.accentBlue)
                        : Color(AppConstants.softNavy),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    sound['name']!,
                    style: TextStyle(
                      color:    selected
                          ? Colors.white
                          : Color(AppConstants.lavendorText),
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Fixed wave — uses AnimationController properly
  Widget _buildSoundWave() {
    return AnimatedBuilder(
      animation: _waveAnim,
      builder: (context, child) {
        final heights = [8.0, 14.0, 22.0, 32.0, 38.0,
                         32.0, 22.0, 14.0, 8.0];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(9, (i) {
            final baseH = heights[i];
            final animH = _isPlaying
                ? baseH * (0.5 + _waveAnim.value *
                    (0.5 + (i % 3) * 0.2))
                : 5.0;
            return AnimatedContainer(
              duration: Duration(
                milliseconds: 200 + i * 40,
              ),
              curve:  Curves.easeInOut,
              margin: const EdgeInsets.symmetric(
                horizontal: 3,
              ),
              width:  4,
              height: animH,
              decoration: BoxDecoration(
                color:        Color(AppConstants.lavendorText)
                    .withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // LEVEL 2 — Groggy
  // ─────────────────────────────────────────────────────────

  void _enterLevel2() {
    _breatheDone            = false;
    _level2AutoTransitioned = false;
    _breatheCycle           = 0;
    setState(() => _currentView = 'level2_breathe');
    _startBreatheCycle();
  }

  bool _breatheDone = false;

  Widget _buildLevel2Breathe() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Affirmation with animated switcher
          Container(
            height:    56,
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              child: Text(
                _motivationLine,
                key:   ValueKey(_motivationLine),
                style: TextStyle(
                  color:     Color(AppConstants.lavendorText),
                  fontSize:  15,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Breathing circle
          Expanded(
            child: Center(
              child: AnimatedBuilder(
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
                            color: Color(
                                AppConstants.accentBlue)
                                .withOpacity(0.35),
                            blurRadius:   35,
                            spreadRadius: 12,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          Text(
                            _breathePhase,
                            style: const TextStyle(
                              color:    Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$_breatheCount',
                            style: TextStyle(
                              color:      Color(
                                  AppConstants.lavendorText),
                              fontSize:   34,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'cycle ${_breatheCycle + 1}'
                            ' of $_totalBreatheCycles',
                            style: TextStyle(
                              color:    Color(
                                  AppConstants.lavendorText)
                                  .withOpacity(0.4),
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _level2Button(
                'Sounds',
                Icons.music_note_rounded,
                _switchToLevel2Sounds,
              ),
              _level2Button(
                'Journal',
                Icons.edit_note_rounded,
                () => setState(
                  () => _currentView = 'level2_journal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _level2Button(
    String        label,
    IconData      icon,
    VoidCallback  onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20, vertical: 12,
        ),
        decoration: BoxDecoration(
          color:        Color(AppConstants.softNavy),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Color(AppConstants.lavendorText),
              size:  18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
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

  // ── Level 2 Sounds ───────────────────────────────────────

  void _switchToLevel2Sounds() {
    _stopBreathe();
    setState(() => _currentView = 'level2_sounds');
    _playSound('audio/white_noise.mp3', 'White noise');
  }

  Widget _buildLevel2Sounds() {
    final sounds = [
      {'name': 'White noise',  'file': 'audio/white_noise.mp3'},
      {'name': 'Falling rain',  'file': 'audio/new_rain.mp3'},
      {'name': 'Sleep music',  'file': 'audio/sleep_music.mp3'},
      {'name': 'Silent valley',  'file': 'audio/silent_valley.mp3'},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Choose what helps you drift off.',
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.6),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 32),

          ...sounds.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () => _toggleNamedSound(
                s['file']!, s['name']!,
              ),
              child: Container(
                width:   double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _currentSound == s['name']
                      ? Color(AppConstants.accentBlue)
                      : Color(AppConstants.softNavy),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _currentSound == s['name'] &&
                              _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      s['name']!,
                      style: const TextStyle(
                        color:    Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    if (_currentSound == s['name'] &&
                        _isPlaying)
                      Text(
                        'playing',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          )),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _level2Button(
                'Breathe',
                Icons.air_rounded,
                () {
                  setState(
                    () => _currentView = 'level2_breathe',
                  );
                  _startBreatheCycle();
                },
              ),
              _level2Button(
                'Journal',
                Icons.edit_note_rounded,
                () => setState(
                  () => _currentView = 'level2_journal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Level 2 Journal ──────────────────────────────────────

  Widget _buildJournalView() {
    final prompts = [
      'What is on your mind right now?',
      'What would make tomorrow feel easier?',
      'What do you need to let go of tonight?',
      'What are you grateful for today?',
      'What is one thing that went well today?',
      'What would you tell a friend feeling this way?',
    ];
    final prompt =
        prompts[_random.nextInt(prompts.length)];

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
                color:  Colors.white,
                height: 1.6,
              ),
              decoration: InputDecoration(
                hintText:  'Just write... no one will see this.',
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveJournal,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Color(AppConstants.accentBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Save and continue',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveJournal() async {
    final text = _journalCtrl.text.trim();
    print('[Journal] Saving: "$text"');

    if (text.isEmpty) {
      print('[Journal] Empty — skipping');
      setState(() => _currentView = 'level2_breathe');
      _startBreatheCycle();
      return;
    }

    bool savedOk = false;
    try {
      await StorageService.saveJournalEntry(text);
      final entries =
          await StorageService.getJournalEntries();
      savedOk = entries.any((e) => e['text'] == text);
      print('[Journal] Saved OK: $savedOk — '
            'Total: ${entries.length}');
    } catch (e) {
      print('[Journal] ERROR: $e');
    }

    _journalCtrl.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedOk ? 'Note saved.' : 'Could not save note.',
            style: TextStyle(
              color: Color(AppConstants.lavendorText),
            ),
          ),
          backgroundColor: Color(AppConstants.softNavy),
          duration:        const Duration(seconds: 2),
          behavior:        SnackBarBehavior.floating,
        ),
      );
      setState(() => _currentView = 'level2_breathe');
      _startBreatheCycle();
    }
  }

  // ─────────────────────────────────────────────────────────
  // LEVEL 3 — Restless
  // ─────────────────────────────────────────────────────────

  void _enterLevel3() {
    setState(() {
      _currentView = 'level3';
      _level3Tab   = 0;
    });
    _startBlinkExercise();
  }

  Widget _buildLevel3() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _level3TabButton('Blink',      0),
              _level3TabButton('Follow',     1),
              _level3TabButton('Hide & Seek', 2),
              _level3TabButton('Yoga Nidra', 3),
            ],
          ),
        ),
        Expanded(child: _buildLevel3Content()),
      ],
    );
  }

  Widget _level3TabButton(String label, int index) {
    final selected = _level3Tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchLevel3Tab(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? Color(AppConstants.accentBlue)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected
                  ? Colors.white
                  : Color(AppConstants.lavendorText)
                      .withOpacity(0.4),
              fontSize:   11,
              fontWeight: selected
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  void _switchLevel3Tab(int index) {
    _blinkTimer?.cancel();
    _ballTimer?.cancel();
    _followTimer?.cancel();
    setState(() => _level3Tab = index);
    if (index == 0) _startBlinkExercise();
    if (index == 1) _startBallFollow();
    if (index == 2) _startBallGame();
    if (index == 3) _startYogaNidra();
  }

  Widget _buildLevel3Content() {
    switch (_level3Tab) {
      case 0:  return _buildBlinkExercise();
      case 1:  return _buildBallFollow();
      case 2:  return _buildBallGame();
      case 3:  return _buildYogaNidra();
      default: return _buildBlinkExercise();
    }
  }

  // ── Blink Exercise ───────────────────────────────────────

  void _startBlinkExercise() {
    setState(() {
      _blinkSeconds = 30;
      _blinkDone    = false;
    });
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (!mounted) { t.cancel(); return; }
        setState(() {
          if (_blinkSeconds > 0) {
            _blinkSeconds--;
          } else {
            _blinkDone = true;
            t.cancel();
          }
        });
      },
    );
  }

  Widget _buildBlinkExercise() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_blinkDone) ...[
            Text(
              'Blink rapidly and continuously',
              style: TextStyle(
                color:    Color(AppConstants.lightText),
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Keep blinking until the timer ends.\n'
              'This tires your eye muscles naturally.',
              style: TextStyle(
                color:    Color(AppConstants.lavendorText)
                    .withOpacity(0.5),
                fontSize: 12,
                height:   1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Container(
              width:  130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(AppConstants.softNavy),
                boxShadow: [
                  BoxShadow(
                    color: Color(AppConstants.accentBlue)
                        .withOpacity(0.3),
                    blurRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$_blinkSeconds',
                  style: TextStyle(
                    color:      Color(AppConstants.lavendorText),
                    fontSize:   48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'seconds',
              style: TextStyle(
                color:    Color(AppConstants.lavendorText)
                    .withOpacity(0.4),
                fontSize: 12,
              ),
            ),
          ] else ...[
            Text(
              'Good.\nNow soften your gaze\non this point.',
              style: TextStyle(
                color:    Color(AppConstants.lightText),
                fontSize: 20,
                height:   1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Container(
              width:  24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(AppConstants.accentBlue)
                    .withOpacity(0.5),
                boxShadow: [
                  BoxShadow(
                    color: Color(AppConstants.accentBlue)
                        .withOpacity(0.3),
                    blurRadius:   12,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            TextButton(
              onPressed: _startBlinkExercise,
              child: Text(
                'do it again',
                style: TextStyle(
                  color: Color(AppConstants.lavendorText)
                      .withOpacity(0.4),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Ball Follow Game ─────────────────────────────────────

  void _startBallFollow() {
    setState(() {
      _followX           = 0.5;
      _followY           = 0.5;
      _followVisible     = true;
      _followInstruction = 'Follow the star with your eyes';
      _followVelocity    = Offset(
        (_random.nextBool() ? 1 : -1) * 0.004,
        (_random.nextBool() ? 1 : -1) * 0.003,
      );
    });

    _followTimer?.cancel();
    _followTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) {
        if (!mounted || _level3Tab != 1) return;
        setState(() {
          _followX += _followVelocity.dx;
          _followY += _followVelocity.dy;

          if (_followX <= 0.1 || _followX >= 0.9) {
            _followVelocity = Offset(
              -_followVelocity.dx +
                  (_random.nextDouble() - 0.5) * 0.001,
              _followVelocity.dy,
            );
          }
          if (_followY <= 0.1 || _followY >= 0.9) {
            _followVelocity = Offset(
              _followVelocity.dx,
              -_followVelocity.dy +
                  (_random.nextDouble() - 0.5) * 0.001,
            );
          }
          _followX = _followX.clamp(0.1, 0.9);
          _followY = _followY.clamp(0.1, 0.9);
        });
      },
    );

    // Disappear every 8 seconds
    Timer.periodic(const Duration(seconds: 8), (t) {
      if (!mounted || _level3Tab != 1) {
        t.cancel();
        return;
      }
      setState(() {
        _followVisible     = false;
        _followInstruction = 'Where will it appear next?';
      });
      HapticFeedback.lightImpact();
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          _followVisible     = true;
          _followInstruction = 'Follow the star with your eyes';
          _followX = 0.2 + _random.nextDouble() * 0.6;
          _followY = 0.2 + _random.nextDouble() * 0.6;
          _followVelocity = Offset(
            (_random.nextBool() ? 1 : -1) *
                (0.003 + _random.nextDouble() * 0.002),
            (_random.nextBool() ? 1 : -1) *
                (0.002 + _random.nextDouble() * 0.002),
          );
        });
      });
    });
  }

  Widget _buildBallFollow() {
    return Stack(
      children: [
        Positioned(
          top:   16,
          left:  0,
          right: 0,
          child: Text(
            _followInstruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ),

        if (_followVisible)
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  Positioned(
                    left: constraints.maxWidth *
                          _followX - 20,
                    top:  constraints.maxHeight *
                          _followY - 20,
                    child: Container(
                      width:  40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(AppConstants.accentBlue)
                            .withOpacity(0.85),
                        boxShadow: [
                          BoxShadow(
                            color: Color(
                                AppConstants.accentBlue)
                                .withOpacity(0.5),
                            blurRadius:   16,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '✦',
                          style: TextStyle(
                            color:    Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        else
          Center(
            child: Text(
              '...',
              style: TextStyle(
                color:    Color(AppConstants.lavendorText)
                    .withOpacity(0.3),
                fontSize: 28,
              ),
            ),
          ),

        Positioned(
          bottom: 16,
          left:   0,
          right:  0,
          child: Text(
            'Let your eyes follow naturally.\nDo not move your head.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.25),
              fontSize: 11,
              height:   1.5,
            ),
          ),
        ),
      ],
    );
  }

  // ── Ball Hide & Seek ─────────────────────────────────────

  void _startBallGame() {
    setState(() {
      _ballRound       = 0;
      _ballVisible     = true;
      _ballX           = 0.5;
      _ballY           = 0.5;
      _ballInstruction = 'Look at the star';
    });
    _runBallRound();
  }

  void _runBallRound() {
    if (_ballRound >= 8) {
      setState(() {
        _ballInstruction = 'Well done.\nClose your eyes and rest.';
        _ballVisible     = false;
      });
      return;
    }

    setState(() {
      _ballVisible     = true;
      _ballInstruction = 'Look at the star';
      _ballX           = 0.15 + _random.nextDouble() * 0.7;
      _ballY           = 0.15 + _random.nextDouble() * 0.7;
    });
    // Vibrate when star appears — open eyes
    HapticFeedback.lightImpact();

    _ballTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _ballVisible     = false;
        _ballInstruction = 'Close your eyes';
      });
      // Stronger vibration when eyes should close
      HapticFeedback.heavyImpact();

      _ballTimer = Timer(const Duration(seconds: 5), () {
        if (!mounted) return;
        // Vibrate again when eyes should open
        HapticFeedback.mediumImpact();
        setState(() => _ballRound++);
        _runBallRound();
      });
    });
  }

  Widget _buildBallGame() {
    if (_ballRound >= 8) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Well done.\n\nClose your eyes\nand rest.',
            style: TextStyle(
              color:    Color(AppConstants.lightText),
              fontSize: 22,
              height:   1.8,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned(
          top:   16,
          left:  0,
          right: 0,
          child: Text(
            _ballInstruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              color:    Color(AppConstants.lavendorText),
              fontSize: 16,
            ),
          ),
        ),

        if (_ballVisible)
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(
                      milliseconds: 600,
                    ),
                    curve: Curves.easeInOut,
                    left: constraints.maxWidth *
                          _ballX - 24,
                    top:  constraints.maxHeight *
                          _ballY - 24,
                    child: Container(
                      width:  48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(AppConstants.accentBlue)
                            .withOpacity(0.85),
                        boxShadow: [
                          BoxShadow(
                            color: Color(
                                AppConstants.accentBlue)
                                .withOpacity(0.5),
                            blurRadius:   20,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '✦',
                          style: TextStyle(
                            color:    Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          )
        else
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'eyes closed...',
                  style: TextStyle(
                    color:    Color(AppConstants.lavendorText)
                        .withOpacity(0.3),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'opening in a moment',
                  style: TextStyle(
                    color:    Color(AppConstants.lavendorText)
                        .withOpacity(0.2),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),

        Positioned(
          bottom: 16,
          left:   0,
          right:  0,
          child: Text(
            'Round ${_ballRound + 1} of 8',
            textAlign: TextAlign.center,
            style: TextStyle(
              color:    Color(AppConstants.lavendorText)
                  .withOpacity(0.25),
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  // ── Yoga Nidra ───────────────────────────────────────────

  void _startYogaNidra() {
    setState(() => _yogaStep = 0);
  }

  Widget _buildYogaNidra() {
    if (_yogaStep >= _yogaSteps.length) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Stay here.\n\nLet sleep\nfind you.',
            style: TextStyle(
              color:      Color(AppConstants.lightText),
              fontSize:   24,
              height:     1.8,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final step = _yogaSteps[_yogaStep];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _yogaSteps.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(
                  horizontal: 3,
                ),
                width:  i == _yogaStep ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _yogaStep
                      ? Color(AppConstants.accentBlue)
                      : Color(AppConstants.lavendorText)
                          .withOpacity(0.25),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            step['title']!,
            style: const TextStyle(
              color:      Colors.white,
              fontSize:   20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Text(
                step['instruction']!,
                style: TextStyle(
                  color:    Color(AppConstants.lavendorText)
                      .withOpacity(0.85),
                  fontSize: 15,
                  height:   2.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => setState(() => _yogaStep++),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(AppConstants.softNavy),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _yogaStep == _yogaSteps.length - 1
                    ? 'finish'
                    : 'next  →',
                style: TextStyle(
                  color:    Color(AppConstants.lavendorText),
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SHARED HELPERS
  // ─────────────────────────────────────────────────────────

  Future<void> _playSound(String file, String name) async {
    await _audioPlayer.stop();
    await _audioPlayer.setReleaseMode(ReleaseMode.loop);
    await _audioPlayer.play(AssetSource(file));
    setState(() {
      _isPlaying    = true;
      _currentSound = name;
    });
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      await _audioPlayer.resume();
      setState(() => _isPlaying = true);
    }
  }

  Future<void> _toggleNamedSound(
    String file, String name,
  ) async {
    if (_currentSound == name) {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.resume();
        setState(() => _isPlaying = true);
      }
    } else {
      await _playSound(file, name);
    }
  }

  // ── Breathing ────────────────────────────────────────────

  void _startBreatheCycle() {
    _breatheTimer?.cancel();
    _breatheController.stop();
    _breatheDone   = false;
    _breatheCycle  = 0;
    _breatheInhale();
  }

  void _stopBreathe() {
    _breatheTimer?.cancel();
    _breatheController.stop();
  }

  void _breatheInhale() {
    if (!mounted || _currentView != 'level2_breathe') return;
    HapticFeedback.heavyImpact();
    _setRandomAffirmation(isInhale: true);
    setState(() {
      _breathePhase = 'Inhale';
      _breatheCount = 4;
    });
    _breatheController.forward(from: 0);
    _breatheCountdown(4, _breatheHold);
  }

  void _breatheHold() {
    if (!mounted || _currentView != 'level2_breathe') return;
    HapticFeedback.lightImpact();
    setState(() {
      _breathePhase   = 'Hold';
      _breatheCount   = 7;
      _motivationLine = '';
    });
    _breatheCountdown(7, _breatheExhale);
  }

  void _breatheExhale() {
    if (!mounted || _currentView != 'level2_breathe') return;
    HapticFeedback.mediumImpact();
    _setRandomAffirmation(isInhale: false);
    setState(() {
      _breathePhase = 'Exhale';
      _breatheCount = 8;
    });
    _breatheController.reverse();
    _breatheCountdown(8, () {
      _breatheCycle++;
      if (_breatheCycle >= _totalBreatheCycles &&
          !_level2AutoTransitioned) {
        _level2AutoTransitioned = true;
        _switchToLevel2Sounds();
      } else {
        _breatheInhale();
      }
    });
  }

  void _breatheCountdown(int seconds, VoidCallback onDone) {
    int remaining = seconds;
    _breatheTimer?.cancel();
    _breatheTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) {
        if (!mounted) { t.cancel(); return; }
        remaining--;
        setState(() => _breatheCount = remaining);
        if (remaining <= 0) {
          t.cancel();
          onDone();
        }
      },
    );
  }

  // ── Navigation ───────────────────────────────────────────

  void _goBack() async {
    _stopBreathe();
    _blinkTimer?.cancel();
    _ballTimer?.cancel();
    _followTimer?.cancel();
    await _audioPlayer.stop();

    if (_currentView == 'level_select') {
      Navigator.pushReplacementNamed(context, '/home_night');
    } else if (_currentView == 'level2_journal') {
      setState(() => _currentView = 'level2_breathe');
      _startBreatheCycle();
    } else {
      setState(() {
        _currentView  = 'level_select';
        _isPlaying    = false;
        _currentSound = '';
      });
    }
  }
}