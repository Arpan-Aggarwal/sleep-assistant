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

  Map<String, dynamic>       _sessionData    = {};
  bool                       _loading        = true;
  bool                       _feedbackGiven  = false;
  List<Map<String, dynamic>> _journalEntries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);

    final cache   = await StorageService.getCache();
    final journal = await StorageService.getJournalEntries();

    print('[DayScreen] Cache: $cache');
    print('[DayScreen] Journal count: ${journal.length}');

    if (mounted) {
      setState(() {
        _sessionData    = cache;
        _feedbackGiven  = cache['feedbackGiven'] == true;
        _journalEntries = journal;
        _loading        = false;
      });
    }
  }

  String _generateInsight() {
    final risk       = _sessionData['riskScore']       ?? '--';
    final screenTime = _sessionData['totalScreenTime'] ?? 0;
    final unlocks    = _sessionData['unlockCount']     ?? 0;

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

  Future<void> _loadTestData() async {
    await StorageService.saveCache({
      'riskScore':       'High',
      'totalScreenTime': 47,
      'unlockCount':     13,
      'longestSession':  22,
      'nudgeSent':       false,
      'feedbackGiven':   false,
    });
    await StorageService.saveJournalEntry(
      'Test entry — feeling restless tonight'
    );
    await _loadData();
  }

  Future<void> _deleteEntry(String id) async {
    await StorageService.deleteJournalEntry(id);
    final updated = await StorageService.getJournalEntries();
    setState(() => _journalEntries = updated);
  }

  Future<void> _clearAllJournal() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Color(AppConstants.softNavy),
        title: const Text(
          'Clear all notes?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(
            color: Color(AppConstants.lavendorText),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Color(AppConstants.lavendorText),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Clear all',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await StorageService.clearAllJournal();
      setState(() => _journalEntries = []);
    }
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
                      mainAxisAlignment:
                          MainAxisAlignment.spaceAround,
                      children: [
                        _statCard('Screen time', '$screenTime mins'),
                        _statCard('Unlocks',     '$unlocks'),
                        _statCard('Longest',     '$longest mins'),
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

                    // ── Journal entries
                    if (_journalEntries.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Your notes',
                            style: TextStyle(
                              color:      Color(AppConstants.lightText),
                              fontSize:   16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton(
                            onPressed: _clearAllJournal,
                            child: Text(
                              'Clear all',
                              style: TextStyle(
                                color:    Color(AppConstants.lavendorText)
                                    .withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._journalEntries.map(
                        (entry) => _journalCard(entry)
                      ),
                      const SizedBox(height: 24),
                    ],

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

                    const SizedBox(height: 32),

                    // ── Test button (subtle, always visible)
                    TextButton(
                      onPressed: _loadTestData,
                      child: Text(
                        'load test data',
                        style: TextStyle(
                          color:    Color(AppConstants.lavendorText)
                              .withOpacity(0.25),
                          fontSize: 11,
                        ),
                      ),
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

  Widget _journalCard(Map<String, dynamic> entry) {
    final text      = entry['text']      ?? '';
    final timestamp = entry['timestamp'] ?? '';
    final id        = entry['id']        ?? '';

    String dateStr = '';
    try {
      final dt  = DateTime.parse(timestamp);
      final now = DateTime.now();
      if (dt.day == now.day) {
        dateStr =
            'Today ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (dt.day == now.day - 1) {
        dateStr = 'Yesterday';
      } else {
        dateStr = '${dt.day}/${dt.month}/${dt.year}';
      }
    } catch (e) {
      dateStr = timestamp.substring(0, 10);
    }

    return Container(
      margin:  const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:        Color(AppConstants.softNavy),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Color(AppConstants.lavendorText).withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: TextStyle(
                  color:    Color(AppConstants.lavendorText)
                      .withOpacity(0.5),
                  fontSize: 11,
                ),
              ),
              GestureDetector(
                onTap: () => _deleteEntry(id),
                child: Icon(
                  Icons.close_rounded,
                  color: Color(AppConstants.lavendorText)
                      .withOpacity(0.4),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              color:    Color(AppConstants.lightText)
                  .withOpacity(0.85),
              fontSize: 14,
              height:   1.5,
            ),
          ),
        ],
      ),
    );
  }
}
