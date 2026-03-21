// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/top_page.dart';

void main() {
  runApp(const SmartKujiApp());
}

class SmartKujiApp extends StatelessWidget {
  const SmartKujiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kuji',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      home: const TopPage(), 
    );
  }
}