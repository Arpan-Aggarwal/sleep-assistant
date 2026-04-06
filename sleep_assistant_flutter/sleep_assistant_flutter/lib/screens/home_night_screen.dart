// lib/screens/home_night_screen.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/constants.dart';
import '../services/storage_service.dart';

class HomeNightScreen extends StatefulWidget {
  const HomeNightScreen({super.key});

  @override
  State<HomeNightScreen> createState() => _HomeNightScreenState();
}

class _HomeNightScreenState extends State<HomeNightScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double>    _scaleAnim;
  String _riskText = '';

  @override
  void initState() {
    super.initState();
    _startBreathing();
    _loadRisk();
  }

  void _startBreathing() {
    _controller = AnimationController(
      vsync:    this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadRisk() async {
    final cache = await StorageService.getCache();
    final risk  = cache['riskScore'] ?? '';
    final indicators = {
      'Low':    'calm night',
      'Medium': 'light activity detected',
      'High':   'active night detected',
    };
    if (mounted) {
      setState(() => _riskText = indicators[risk] ?? '');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(AppConstants.darkNavy),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Title
            Positioned(
              top:   20,
              left:  0,
              right: 0,
              child: Text(
                'Sleep Assistant',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:    Color(AppConstants.lavendorText)
                      .withOpacity(0.5),
                  fontSize: 13,
                ),
              ),
            ),

            // ── Risk indicator
            if (_riskText.isNotEmpty)
              Positioned(
                top:   45,
                left:  0,
                right: 0,
                child: Text(
                  _riskText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color:    Color(AppConstants.lavendorText)
                        .withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
              ),

            // ── Breathing circle (center)
            Center(
              child: AnimatedBuilder(
                animation: _scaleAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnim.value,
                    child: Container(
                      width:  200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(AppConstants.softNavy),
                        boxShadow: [
                          BoxShadow(
                            color:      Color(AppConstants.accentBlue)
                                .withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'breathe',
                          style: TextStyle(
                            color:    Color(AppConstants.lavendorText)
                                .withOpacity(0.6),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Calm text
            Positioned(
              bottom: 180,
              left:   0,
              right:  0,
              child: Column(
                children: [
                  Text(
                    'Everything is quiet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:    Color(AppConstants.lightText)
                          .withOpacity(0.9),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Rest easy.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:    Color(AppConstants.lavendorText)
                          .withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // ── Helper text
            Positioned(
              bottom: 110,
              left:   0,
              right:  0,
              child: Text(
                'tap below if your mind is restless',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:    Color(AppConstants.lavendorText)
                      .withOpacity(0.4),
                  fontSize: 11,
                ),
              ),
            ),

            // ── Support button
            Positioned(
              bottom: 40,
              left:   40,
              right:  40,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/support'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.softNavy),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'I need support',
                  style: TextStyle(
                    color:    Color(AppConstants.lavendorText),
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            // TEMPORARY TEST BUTTON - remove after testing
Positioned(
  bottom: 10,
  left:   0,
  right:  0,
  child: TextButton(
    onPressed: () =>
        Navigator.pushReplacementNamed(context, '/home_day'),
    child: Text(
      'view morning dashboard',
      style: TextStyle(
        color:    Color(AppConstants.lavendorText)
            .withOpacity(0.2),
        fontSize: 10,
      ),
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}