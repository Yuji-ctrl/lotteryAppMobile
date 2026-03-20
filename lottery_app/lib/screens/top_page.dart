import 'package:flutter/material.dart';
import 'login_page.dart';
// ① トップ画面
class TopPage extends StatelessWidget {
  const TopPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Smart Kuji', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
            const Text('スマホで引けるコンビニくじ', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
              child: const Text('はじめる'),
            ),
          ],
        ),
      ),
    );
  }
}



