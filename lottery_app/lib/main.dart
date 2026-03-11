import 'package:flutter/material.dart';

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
      // 最初の画面を「トップ画面」に設定
      home: const TopPage(),
    );
  }
}

// ① アプリ名（トップ）
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
            const Text('コンビニのくじをスマートフォンで。\n並ばずに、どこでもくじを引くことができます。', textAlign: TextAlign.center),
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

// ② ホーム画面
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> shops = [
      {'name': 'ローソン 越谷駅前店', 'kuji': 'ワンピースくじ'},
      {'name': 'ファミリーマート 南越谷店', 'kuji': 'ポケモンくじ'},
      {'name': 'セブンイレブン 越谷東口店', 'kuji': 'お菓子くじ'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('近くのコンビニ')),
      body: ListView.builder(
        itemCount: shops.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(shops[index]['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('現在開催中のくじ：${shops[index]['kuji']}'),
              trailing: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const KujiDetailPage())),
                child: const Text('くじを見る'),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ③ くじ詳細画面
class KujiDetailPage extends StatelessWidget {
  const KujiDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ワンピース 一番くじ')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('スマホからくじを引いて、\n当たった景品を店頭で受け取れます。', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 20),
            const Text('景品一覧', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            const ListTile(title: Text('A賞 フィギュア'), trailing: Text('残り 1')),
            const ListTile(title: Text('B賞 タオル'), trailing: Text('残り 3')),
            const ListTile(title: Text('C賞 キーホルダー'), trailing: Text('残り 10')),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LotteryAnimationPage())),
                child: const Text('くじを引く', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ④ 抽選演出画面
class LotteryAnimationPage extends StatefulWidget {
  const LotteryAnimationPage({super.key});

  @override
  State<LotteryAnimationPage> createState() => _LotteryAnimationPageState();
}

class _LotteryAnimationPageState extends State<LotteryAnimationPage> {
  @override
  void initState() {
    super.initState();
    // 2秒後に結果画面へ自動遷移
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ResultPage()));
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
  const ResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('当たり', style: TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('🎉 B賞 当選 🎉', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
              const Text('タオル', style: TextStyle(fontSize: 24)),
              const SizedBox(height: 30),
              const Text('この画面を店舗スタッフに見せてください', textAlign: TextAlign.center),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExchangePage())),
                child: const Text('景品を受け取る'),
              ),
            ],
          ),
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
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('店員がQRコードを読み取ることで\n景品を受け取ることができます。', textAlign: TextAlign.center),
            ),
            const SizedBox(height: 30),
            // QRコードの代わりのアイコン
            const Icon(Icons.qr_code_2, size: 200),
            const SizedBox(height: 10),
            const Text('有効期限：10分', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            const SizedBox(height: 50),
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}