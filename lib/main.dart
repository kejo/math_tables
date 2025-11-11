import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Tables',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const SettingsPage(),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _minController = TextEditingController(text: '2');
  final _maxController = TextEditingController(text: '10');
  final _timerController = TextEditingController(text: '30');

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _timerController.dispose();
    super.dispose();
  }

  void _start() {
    if (_formKey.currentState?.validate() ?? false) {
      final min = int.parse(_minController.text);
      final max = int.parse(_maxController.text);
      final timerSeconds = int.parse(_timerController.text);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => QuizPage(rangeMin: min, rangeMax: max, timeLimitSeconds: timerSeconds),
      ));
    }
  }

  String? _validate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter a number';
    final n = int.tryParse(v);
    if (n == null) return 'Invalid integer';
    if (n < 0) return 'Must be non-negative';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Math Tables - Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select B range (inclusive):', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _minController,
                      decoration: const InputDecoration(labelText: 'Min (B)'),
                      keyboardType: TextInputType.number,
                      validator: _validate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxController,
                      decoration: const InputDecoration(labelText: 'Max (B)'),
                      keyboardType: TextInputType.number,
                      validator: _validate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _timerController,
                decoration: const InputDecoration(labelText: 'Timer seconds'),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final base = _validate(v);
                  if (base != null) return base;
                  final n = int.tryParse(v!);
                  if (n == null) return 'Invalid integer';
                  if (n < 1) return 'Must be at least 1 second';
                  return null;
                },
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () {
                  // additional validation: min <= max and min >=2 ideally
                  final minOk = int.tryParse(_minController.text);
                  final maxOk = int.tryParse(_maxController.text);
                  String? extra;
                  if (minOk == null || maxOk == null) extra = 'Invalid numbers';
                  if (extra == null && minOk! > maxOk!) extra = 'Min must be <= Max';
                  if (extra == null && maxOk! < 2) extra = 'Max should be at least 2';
                  // also validate timer
                  final timerOk = int.tryParse(_timerController.text);
                  if (extra == null && (timerOk == null || timerOk < 1)) extra = 'Timer must be at least 1 second';
                  if (extra != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extra)));
                    return;
                  }
                  _start();
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start'),
              ),
              const SizedBox(height: 12),
              const Text('Notes: A is random 2..9, B is random in your selected range. Timer shows 30s and reveals the answer when time is up.'),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizPage extends StatefulWidget {
  final int rangeMin;
  final int rangeMax;
  final int timeLimitSeconds;

  const QuizPage({super.key, required this.rangeMin, required this.rangeMax, required this.timeLimitSeconds});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  Timer? _timer;
  late int _remaining = widget.timeLimitSeconds;
  int _a = 2;
  int _b = 2;
  bool _revealed = false;
  // Precomputed pairs and iterator index
  final List<Map<String, int>> _pairs = [];
  int _currentIndex = 0;
  // Use a secure RNG for unpredictable shuffling
  final Random _secureRnd = Random.secure();

  @override
  void initState() {
    super.initState();
    _generatePairsAndShuffle();
    _nextPair();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remaining = widget.timeLimitSeconds;
      _revealed = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _revealed = true;
          _timer?.cancel();
        }
      });
    });
  }

  void _generatePairsAndShuffle() {
    _pairs.clear();
    final min = widget.rangeMin;
    final max = widget.rangeMax;
    for (var a = 2; a <= 9; a++) {
      for (var b = min; b <= max; b++) {
        _pairs.add({'a': a, 'b': b});
      }
    }
    // Fisher-Yates shuffle using secure RNG
    for (var i = _pairs.length - 1; i > 0; i--) {
      final j = _secureRnd.nextInt(i + 1);
      final tmp = _pairs[i];
      _pairs[i] = _pairs[j];
      _pairs[j] = tmp;
    }
    _currentIndex = 0;
  }

  void _nextPair() {
    // If we've exhausted all precomputed pairs, show All Done
    if (_currentIndex >= _pairs.length) {
      _showAllDoneDialog();
      return;
    }

    final pair = _pairs[_currentIndex];
    _currentIndex++;
    setState(() {
      _a = pair['a']!;
      _b = pair['b']!;
    });
    _startTimer();
  }

  Future<void> _showAllDoneDialog() async {
    _timer?.cancel();
    final restart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('All Done'),
        content: const Text('You have completed all combinations. Restart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back to Settings'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Restart'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (restart == true) {
      _generatePairsAndShuffle();
      _nextPair();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = _a * _b;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Tables - Quiz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Center(child: Text('What is:', style: Theme.of(context).textTheme.titleLarge)),
            const SizedBox(height: 12),
            Center(
              child: Text('$_b × $_a', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(_revealed ? 'Answer: $product' : 'Time left: $_remaining s', style: const TextStyle(fontSize: 20)),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // instant reveal
                      _timer?.cancel();
                      setState(() {
                        _revealed = true;
                      });
                    },
                    child: const Text('Reveal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _timer?.cancel();
                      _nextPair();
                    },
                    child: const Text('Next'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back to Settings'),
            ),
            const SizedBox(height: 16),
            // Progress bar at the bottom showing completion progress
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0.0),
              child: LinearProgressIndicator(
                value: _pairs.isNotEmpty ? (_currentIndex / _pairs.length) : 0.0,
                minHeight: 8,
                semanticsLabel: 'Progress',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
