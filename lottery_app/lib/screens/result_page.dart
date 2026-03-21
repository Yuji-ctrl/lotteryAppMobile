import 'dart:math';

import 'package:flutter/material.dart';
import '../models/kuji_repository.dart';
import 'exchange_page.dart';

// ⑤ 結果画面
class ResultPage extends StatefulWidget {
  final String resultName;
  final String shopName;
  final String prizeType;

  const ResultPage({
    super.key,
    required this.resultName,
    required this.shopName,
    required this.prizeType,
  });

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late final String redemptionCode;
  bool _decremented = false;

  @override
  void initState() {
    super.initState();
    redemptionCode = 'KUJI-${Random().nextInt(999999).toString().padLeft(6, '0')}';
    _decrementPrize();
  }

  void _decrementPrize() {
    if (_decremented) return;

    setState(() {
      KujiRepository().decrementPrize(widget.shopName, widget.prizeType);
      _decremented = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('当たり', style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('🎉 ${widget.resultName} 当選 🎉', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Text('くじ引き結果が確定しました。'),
            const SizedBox(height: 10),
            Text('引換コード: $redemptionCode', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            const Text('この画面を店舗スタッフに見せてください'),
            const SizedBox(height: 20),
            Builder(
              builder: (context) {
                final shop = KujiRepository().findByShopName(widget.shopName);
                return Text(
                  shop != null
                      ? '残り：A ${shop.prizeA} B ${shop.prizeB} C ${shop.prizeC}'
                      : '残り情報を取得できませんでした',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 30),
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