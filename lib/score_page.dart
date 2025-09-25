import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;

class ScorePage extends StatefulWidget {
  final List<String> players;
  const ScorePage({super.key, required this.players});

  @override
  State<ScorePage> createState() => _ScorePageState();
}

class _ScorePageState extends State<ScorePage> {
  late List<Round> _rounds;

  @override
  void initState() {
    super.initState();
    _rounds = [Round.empty(widget.players.length)]; // start with one empty round
  }

  // Totals are the sum of LOCKED rounds only
  List<int> get _totals {
    final totals = List<int>.filled(widget.players.length, 0);
    for (final r in _rounds) {
      if (r.locked) {
        for (var i = 0; i < r.values.length; i++) {
          totals[i] += r.values[i] ?? 0;
        }
      }
    }
    return totals;
  }

  Future<void> _onCellTap(int rowIndex, int colIndex) async {
    final r = _rounds[rowIndex];

    // Locked → confirm edit entire round
    if (r.locked) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Edit this round?'),
          content: const Text(
              'Editing will clear all scores in this round.\nYou will need to re-enter each score.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Edit round')),
          ],
        ),
      );
      if (ok == true) {
        setState(() {
          _rounds[rowIndex] = Round.empty(widget.players.length)..editing = true;
        });
      }
      return;
    }

    // Otherwise open keypad for this cell
    final current = r.values[colIndex];
    final val = await _showScorePad(initial: current);
    if (val == null) return; // cancelled

    setState(() {
      r.values[colIndex] = val;
    });

    _maybeFinalizeRound(rowIndex);
  }

  void _maybeFinalizeRound(int rowIndex) {
    final r = _rounds[rowIndex];

    // Only validate after ALL cells filled
    if (r.values.any((v) => v == null)) return;

    final sum = r.values.fold<int>(0, (a, b) => a + (b ?? 0));
    if (sum != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Round ${rowIndex + 1} total must equal 0 (currently $sum).'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return; // stay editable so user can fix entries
    }

    // Lock round and add a new empty one at the end
    setState(() {
      r.locked = true;
      r.editing = false;
      if (rowIndex == _rounds.length - 1) {
        _rounds.add(Round.empty(widget.players.length));
      }
    });
  }

  Future<bool> _confirmExit() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave game?'),
        content: const Text(
          'This will delete the current score sheet and return to player setup.'
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete & Leave'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final totals = _totals;

    return WillPopScope(
      onWillPop: _confirmExit, // intercept system/back
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scoring'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (await _confirmExit()) {
                Navigator.of(context).pop();
              }
            },
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Header: player names
              _HeaderBar(
                background: Theme.of(context).colorScheme.primaryContainer,
                children: List.generate(widget.players.length, (i) {
                  return Center(
                    child: Text(
                      widget.players[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  );
                }),
              ),
              // Totals row
              _HeaderBar(
                background: Theme.of(context).colorScheme.secondaryContainer,
                children: List.generate(widget.players.length, (i) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Text(
                        '${totals[i]}',
                        style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 6),

              // Body: rounds list (scrolling)
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _rounds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, rowIndex) {
                    final r = _rounds[rowIndex];
                    final isOdd = rowIndex.isOdd;
                    final baseColor = isOdd
                        ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.45)
                        : Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.25);
                    final bgColor = r.editing
                        ? Colors.red.withOpacity(0.12)
                        : r.locked
                            ? baseColor.withOpacity(0.6)
                            : baseColor;

                    return Container(
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: r.editing
                              ? Colors.red.withOpacity(0.4)
                              : r.locked
                                  ? Theme.of(context).dividerColor
                                  : Theme.of(context).dividerColor.withOpacity(0.4),
                        ),
                      ),
                      child: Row(
                        children: List.generate(widget.players.length, (colIndex) {
                          final v = r.values[colIndex];
                          return Expanded(
                            child: InkWell(
                              onTap: () => _onCellTap(rowIndex, colIndex),
                              borderRadius: _cellRadiusFor(colIndex, widget.players.length),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    right: BorderSide(
                                      color: Theme.of(context).dividerColor.withOpacity(0.35),
                                    ),
                                  ),
                                  borderRadius: _cellRadiusFor(colIndex, widget.players.length),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      v == null ? '—' : '$v',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: r.editing
                                            ? Colors.red.shade800
                                            : (r.locked ? Colors.black87 : Colors.black),
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                    if (r.locked && colIndex == widget.players.length - 1)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(Icons.lock, size: 14, color: Colors.black45),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Rounded corners only at row edges
  BorderRadius _cellRadiusFor(int col, int len) {
    const r = Radius.circular(12);
    if (col == 0) return const BorderRadius.only(topLeft: r, bottomLeft: r);
    if (col == len - 1) return const BorderRadius.only(topRight: r, bottomRight: r);
    return BorderRadius.zero;
  }

  /// Custom keypad bottom sheet: returns an int (can be negative) or null if cancelled.
  Future<int?> _showScorePad({int? initial}) async {
    return showModalBottomSheet<int>(
      context: context,
      // Let the sheet take a larger portion of the screen
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: 0.70, // try 0.65–0.80 to taste
        child: _ScorePad(initial: initial),
      ),
    );
}

}

// ===== Data model =====
class Round {
  List<int?> values; // length = number of players
  bool locked;
  bool editing;
  Round(this.values, {this.locked = false, this.editing = false});
  factory Round.empty(int nPlayers) =>
      Round(List<int?>.filled(nPlayers, null), locked: false, editing: false);
}

// ===== Header row widget =====
class _HeaderBar extends StatelessWidget {
  final List<Widget> children;
  final Color background;
  const _HeaderBar({required this.children, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
          top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: children
            .map((w) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: w,
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ===== Keypad bottom sheet =====
class _ScorePad extends StatefulWidget {
  final int? initial;
  const _ScorePad({this.initial});

  @override
  State<_ScorePad> createState() => _ScorePadState();
}

class _ScorePadState extends State<_ScorePad> {
  String digits = ''; // user-entered digits only

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    if (init != null) {
      // Pre-fill with absolute value; user will choose sign on submit (+/-).
      digits = init.abs().toString();
    }
  }

  String get display => digits.isEmpty ? '0' : digits;
  bool get hasDigits => digits.isNotEmpty;

  void _append(String d) {
    setState(() {
      if (digits == '0') {
        digits = d;
      } else {
        digits += d;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (digits.isNotEmpty) {
        digits = digits.substring(0, digits.length - 1);
      }
    });
  }

  void _clear() {
    setState(() {
      digits = '';
    });
  }

  // Submit immediately with the chosen sign.
  void _submit(bool negative) {
    if (!hasDigits) return; // require at least one digit
    final val = int.parse(digits);
    Navigator.pop(context, negative ? -val : val);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: cs.surfaceVariant.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                // We only show digits; sign is chosen on submit (+/-)
                // If you prefer to preview a sign, we can add a tiny toggle later.
                // Using a const here removes rebuild jank; see below where we draw display.
                '',
              ),
            ),
            // Re-draw display with proper style (outside const block)
            // (Small trick to keep styles and still update value.)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  display,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),

            // Key rows
            _row(['1', '2', '3']),
            _row(['4', '5', '6']),
            _row(['7', '8', '9']),
            Row(
              children: [
                // Make "0" take the left space
                Expanded(
                  child: _btn(label: '0', onTap: () => _append('0')),
                ),
                const Spacer(), // pushes +/− to the right
                // Fixed-width + and − on the right
                SizedBox(
                  width: 65,
                  child: _btn(label: '+', onTap: () => _submit(false)),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 65,
                  child: _btn(label: '-', onTap: () => _submit(true)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                  onPressed: _backspace,
                  child: const Icon(Icons.backspace_outlined),
                ),
                ),
                // No OK button anymore — '+' and '−' act as submit.
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(List<String> labels) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: labels
            .map((l) => Expanded(child: _btn(label: l, onTap: () => _append(l))))
            .expand((w) sync* {
              yield w;
              if (w != labels.last) yield const SizedBox(width: 8);
            })
            .toList(),
      ),
    );
  }

  Widget _btn({required String label, required VoidCallback onTap}) {
    return SizedBox(
      height: 52,
      child: FilledButton.tonal(
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

