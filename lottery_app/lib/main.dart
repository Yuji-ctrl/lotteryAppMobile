// lib/main.dart
import 'package:flutter/material.dart';
import 'screens/login_page.dart'; // ログイン画面をインポート

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
      // homeをLoginPageに変更
      home: const LoginPage(), 
    );
  }
}