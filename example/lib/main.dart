import 'package:flutter/material.dart';
import 'package:flutter_layout_inspector/flutter_layout_inspector.dart';

void main() {
  runApp(
    // ← Just wrap your app here. That's it!
    LayoutInspector(child: const MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Layout Inspector Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Layout Inspector Demo'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Tap the 🔍 button (bottom-right)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('then tap any widget to inspect it'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              child: const Text('I am a Button'),
            ),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 100,
              color: Colors.blue.shade100,
              child: const Center(child: Text('I am a Container')),
            ),
            const SizedBox(height: 16),
            const Icon(Icons.star, size: 48, color: Colors.amber),
          ],
        ),
      ),
    );
  }
}
