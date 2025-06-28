import 'package:flutter/material.dart';
import 'package:treasure_ar_app/presentation/pages/ar_view_page.dart';

void main() {
  runApp(const TreasureARApp());
}

class TreasureARApp extends StatelessWidget {
  const TreasureARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AR宝探しアプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amber.shade50,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.card_giftcard,
                size: 100,
                color: Colors.amber.shade700,
              ),
              const SizedBox(height: 24),
              Text(
                'AR宝探し',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '0-1歳のお子さまと一緒に楽しめる\nAR宝探しゲームです',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ARViewPage()),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('ゲームを始める'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: 使い方ページを表示
                },
                icon: const Icon(Icons.help_outline),
                label: const Text('使い方'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.amber.shade700,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
