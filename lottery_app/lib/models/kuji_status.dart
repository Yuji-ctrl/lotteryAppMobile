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