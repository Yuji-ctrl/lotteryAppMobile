import 'package:flutter/material.dart';
import 'animation_page.dart';

class PaymentPage extends StatelessWidget {
  final String kujiName;
  final String resultName; // 既に決まった抽選結果を引き継ぐ
  final String shopName;
  final String prizeType;

  const PaymentPage({
    super.key,
    required this.kujiName,
    required this.resultName,
    required this.shopName,
    required this.prizeType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('お支払い')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('購入内容', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.grey[100],
              title: Text(kujiName),
              trailing: const Text('¥700', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),
            const Text('支払い方法', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            RadioListTile(value: 0, groupValue: 0, onChanged: (v) {}, title: const Text('クレジットカード')),
            RadioListTile(value: 1, groupValue: 0, onChanged: (v) {}, title: const Text('PayPay')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                onPressed: () {
                  // 決済完了後、抽選演出へ
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LotteryAnimationPage(
                        resultName: resultName,
                        shopName: shopName,
                        prizeType: prizeType,
                      ),
                    ),
                  );
                },
                child: const Text('決済を確定してくじを引く', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}