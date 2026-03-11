import 'package:flutter/material.dart';
import 'exchange_page.dart';
// ⑤ 結果画面
class ResultPage extends StatelessWidget {
  final String resultName;
  const ResultPage({super.key, required this.resultName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('当たり', style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('🎉 $resultName 当選 🎉', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            const Text('この画面を店舗スタッフに見せてください'),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExchangePage())),
              child: const Text('景品を受け取る'),
            ),
          ],
        ),
      ),
    );
  }
}