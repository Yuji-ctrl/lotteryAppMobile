import 'package:flutter/material.dart';
import '../models/kuji_status.dart'; // モデルを読み込む
import 'detail_page.dart';

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