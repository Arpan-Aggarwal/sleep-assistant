// lib/screens/home_day_screen.dart
import 'package:flutter/material.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';

class HomeDayScreen extends StatefulWidget {
  const HomeDayScreen({super.key});

  @override
  State<HomeDayScreen> createState() => _HomeDayScreenState();
}

class _HomeDayScreenState extends State<HomeDayScreen> {

  Map<String, dynamic> _sessionData = {};
  bool _loading       = true;
  bool _feedbackGiven = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final cache = await StorageService.getCache();
    if (mounted) {
      setState(() {
        _sessionData    = cache;
        _feedbackGiven  = cache['feedbackGiven'] == true;
        _loading        = false;
      });
    }
  }

  String _generateInsight() {
    final risk        = _sessionData['riskScore']       ?? '--';
    final screenTime  = _sessionData['totalScreenTime'] ?? 0;
    final unlocks     = _sessionData['unlockCount']     ?? 0;
    final longest     = _sessionData['longestSession']  ?? 0;

    if (risk == 'High') {
      if (screenTime > 40) {
        return 'You spent a lot of time on your phone last night. '
               'Try putting it face-down 30 mins before sleep.';
      } else if (unlocks > 10) {
        return 'Frequent phone checks signal restlessness. '
               'A short breathing exercise before bed may help.';
      }
      return 'Last night showed high sleep disruption. '
             'Consider a wind-down routine tonight.';
    } else if (risk == 'Medium') {
      return 'Moderate activity last night. '
             'Small adjustments tonight will help.';
    } else if (risk == 'Low') {
      return 'Great night. Low phone activity detected. '
             'Keep this rhythm going.';
    }
    return 'Your sleep data will appear here '
           'after your first tracked night.';
  }

  Color _riskColor(String risk) {
    switch (risk) {
      case 'High':   return const Color(0xFFE08888);
      case 'Medium': return const Color(0xFFF0D080);
      case 'Low':    return const Color(0xFF88C888);
      default:       return Colors.white54;
    }
  }

  Future<void> _saveFeedback(bool helped) async {
    final userId = await StorageService.getUserId() ?? '';
    final risk   = _sessionData['riskScore'] ?? '--';

    await ApiService.saveFeedback(
      userId:    userId,
      helped:    helped,
      riskScore: risk,
    );

    final cache = await StorageService.getCache();
    cache['feedbackGiven'] = true;
    await StorageService.saveCache(cache);

    setState(() => _feedbackGiven = true);
  }

  @override
  Widget build(BuildContext context) {
    final risk       = _sessionData['riskScore']       ?? '--';
    final screenTime = _sessionData['totalScreenTime'] ?? 0;
    final unlocks    = _sessionData['unlockCount']     ?? 0;
    final longest    = _sessionData['longestSession']  ?? 0;

    return Scaffold(
      backgroundColor: Color(AppConstants.darkNavy),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF7B8FBF),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    // ── Title
                    Text(
                      'Good morning',
                      style: TextStyle(
                        color:    Color(AppConstants.lavendorText)
                            .withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Last night',
                      style: TextStyle(
                        color:    Color(AppConstants.lavendorText)
                            .withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── Risk score
                    Text(
                      risk,
                      style: TextStyle(
                        color:      _riskColor(risk),
                        fontSize:   48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'sleep disruption risk',
                      style: TextStyle(
                        color:    Color(AppConstants.lavendorText)
                            .withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Divider
                    Divider(
                      color: Color(AppConstants.lavendorText)
                          .withOpacity(0.15),
                    ),
                    const SizedBox(height: 24),

                    // ── Stats row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statCard('Screen time', '$screenTime mins'),
                        _statCard('Unlocks', '$unlocks'),
                        _statCard('Longest', '$longest mins'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Insight card
                    Container(
                      width:   double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color:        Color(AppConstants.softNavy),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _generateInsight(),
                        style: TextStyle(
                          color:    Color(AppConstants.lavendorText),
                          fontSize: 13,
                          height:   1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // ── Feedback
                    if (!_feedbackGiven) ...[
                      Text(
                        'Did last night feel better?',
                        style: TextStyle(
                          color:    Color(AppConstants.lavendorText)
                              .withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _saveFeedback(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF1A3020),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Yes, slept well',
                                style: TextStyle(
                                  color: Color(0xFF88C888),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _saveFeedback(false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF201828),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Not really',
                                style: TextStyle(
                                  color: Color(0xFFB088C0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      Text(
                        'Thank you. We will adjust for tonight.',
                        style: TextStyle(
                          color:    Color(AppConstants.lavendorText)
                              .withOpacity(0.6),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color:      Colors.white,
            fontSize:   18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color:    Color(AppConstants.lavendorText)
                .withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}