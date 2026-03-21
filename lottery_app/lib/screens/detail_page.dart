import 'package:flutter/material.dart';
import '../models/kuji_status.dart';
import 'dart:math';
import 'payment_page.dart';
// ③ くじ詳細画面
class KujiDetailPage extends StatefulWidget {
  final KujiStatus status;
  const KujiDetailPage({super.key, required this.status});

  @override
  State<KujiDetailPage> createState() => _KujiDetailPageState();
}

class _KujiDetailPageState extends State<KujiDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.status.kujiName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('スマホからくじを引いて、当たった景品を店頭で受け取れます。'),
            const SizedBox(height: 20),
            Text('景品一覧 (${widget.status.shopName})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _prizeTile('A賞 フィギュア', widget.status.prizeA),
            _prizeTile('B賞 タオル', widget.status.prizeB),
            _prizeTile('C賞 キーホルダー', widget.status.prizeC),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.status.isSoldOut ? Colors.grey : Colors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: widget.status.isSoldOut ? null : () => _drawKuji(),
                child: Text(widget.status.isSoldOut ? '完売しました' : 'くじを引く', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _prizeTile(String name, int count) {
    return ListTile(
      title: Text(name),
      trailing: Text(count <= 0 ? '終了' : '残り $count', 
        style: TextStyle(color: count <= 0 ? Colors.red : Colors.black, fontWeight: FontWeight.bold)),
    );
  }

  void _drawKuji() {
    List<String> pool = [];
    if (widget.status.prizeA > 0) pool.add("A");
    if (widget.status.prizeB > 0) pool.add("B");
    if (widget.status.prizeC > 0) pool.add("C");

    final random = Random();
    String pick = pool[random.nextInt(pool.length)];

    String resultName = "";
    String prizeType = "";
    if (pick == "A") {
      prizeType = "A";
      resultName = "A賞 フィギュア";
    } else if (pick == "B") {
      prizeType = "B";
      resultName = "B賞 タオル";
    } else {
      prizeType = "C";
      resultName = "C賞 キーホルダー";
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentPage(
          kujiName: widget.status.kujiName,
          resultName: resultName,
          shopName: widget.status.shopName,
          prizeType: prizeType,
        ),
      ),
    );
  }
}
