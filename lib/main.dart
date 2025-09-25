import 'package:flutter/material.dart';
import 'players_setup_page.dart';

void main() {
  runApp(const ScoreKeeperApp());
}

class ScoreKeeperApp extends StatelessWidget {
  const ScoreKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Score Keeper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      home: const PlayersSetupPage(),
    );
  }
}
