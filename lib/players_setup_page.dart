import 'package:flutter/material.dart';
import 'score_page.dart';

class PlayersSetupPage extends StatefulWidget {
  const PlayersSetupPage({super.key});

  @override
  State<PlayersSetupPage> createState() => _PlayersSetupPageState();
}

class _PlayersSetupPageState extends State<PlayersSetupPage> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  List<String> get _filledNames =>
      _controllers.map((c) => c.text.trim()).where((t) => t.isNotEmpty).toList();

  bool get _canProceed => _filledNames.length >= 2;

  void _goNext() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ScorePage(players: _filledNames)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Score Keeper')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Enter player names (2–6)',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              ...List.generate(6, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text('${i + 1}.',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                            )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          textInputAction:
                              i < 5 ? TextInputAction.next : TextInputAction.done,
                          onSubmitted: (_) {
                            if (i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            } else {
                              FocusScope.of(context).unfocus();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Player ${i + 1} name',
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          autocorrect: false,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    _canProceed ? Icons.check_circle : Icons.error_outline,
                    color: _canProceed ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _canProceed
                        ? '${_filledNames.length} player(s) ready'
                        : 'Enter at least 2 names',
                    style: TextStyle(
                      color: _canProceed ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _canProceed ? _goNext : null,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
