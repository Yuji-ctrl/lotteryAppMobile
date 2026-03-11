import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const SmartKujiApp());
}

// 景品の状態を管理するクラス（店舗ごとにインスタンス化）
class KujiStatus {
  final String shopName;
  final String kujiName;
  int prizeA;
  int prizeB;
  int prizeC;

  KujiStatus({
    required this.shopName,
    required this.kujiName,
    this.prizeA = 1,
    this.prizeB = 3,
    this.prizeC = 10,
  });

  bool get isSoldOut => (prizeA + prizeB + prizeC) <= 0;
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HomePage())),
              child: const Text('はじめる'),
            ),
          ],
        ),
      ),
    );
  }
}

// ② ホーム画面（すべての店舗を引けるように修正）
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 全店舗の在庫データをリストで保持
  final List<KujiStatus> _allShops = [
    KujiStatus(shopName: 'ローソン 越谷駅前店', kujiName: 'ワンピース 一番くじ'),
    KujiStatus(shopName: 'ファミリーマート 南越谷店', kujiName: 'ポケモンくじ', prizeA: 2, prizeB: 5, prizeC: 15),
    KujiStatus(shopName: 'セブンイレブン 越谷東口店', kujiName: 'お菓子くじ', prizeA: 5, prizeB: 10, prizeC: 30),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('近くのコンビニ')),
      body: ListView.builder(
        itemCount: _allShops.length,
        itemBuilder: (context, index) {
          final shop = _allShops[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            color: shop.isSoldOut ? Colors.grey[300] : Colors.white,
            child: ListTile(
              title: Text(shop.shopName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('開催中：${shop.kujiName}${shop.isSoldOut ? " (完売)" : ""}'),
              trailing: ElevatedButton(
                onPressed: shop.isSoldOut 
                  ? null 
                  : () async {
                      // 詳細画面へデータを渡し、戻ってきたら画面を更新する
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => KujiDetailPage(status: shop)),
                      );
                      setState(() {}); // 戻ってきた時に在庫数を反映させる
                    },
                child: Text(shop.isSoldOut ? '完売' : 'くじを見る'),
              ),
            ),
          );
        },
      ),
    );
  }
}

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
    setState(() {
      if (pick == "A") {
        widget.status.prizeA--;
        resultName = "A賞 フィギュア";
      } else if (pick == "B") {
        widget.status.prizeB--;
        resultName = "B賞 タオル";
      } else {
        widget.status.prizeC--;
        resultName = "C賞 キーホルダー";
      }
    });

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LotteryAnimationPage(resultName: resultName)),
    );
  }
}

// ④ 抽選演出画面
class LotteryAnimationPage extends StatefulWidget {
  final String resultName;
  const LotteryAnimationPage({super.key, required this.resultName});

  @override
  State<LotteryAnimationPage> createState() => _LotteryAnimationPageState();
}

class _LotteryAnimationPageState extends State<LotteryAnimationPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ResultPage(resultName: widget.resultName)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('くじを引いています…', style: TextStyle(fontSize: 20)),
            Text('結果をお待ちください'),
          ],
        ),
      ),
    );
  }
}

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