import 'package:flutter/material.dart';
// ⑥ 引き換え画面
class ExchangePage extends StatelessWidget {
  const ExchangePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('景品引き換え')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('店員がQRコードを読み取ることで\n景品を受け取ることができます。', textAlign: TextAlign.center),
            const SizedBox(height: 30),
            const Icon(Icons.qr_code_2, size: 200),
            const Text('有効期限：10分', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}