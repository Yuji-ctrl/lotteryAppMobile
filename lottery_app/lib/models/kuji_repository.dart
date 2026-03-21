import 'dart:convert';

import 'kuji_status.dart';

class KujiRepository {
  KujiRepository._privateConstructor();
  static final KujiRepository _instance = KujiRepository._privateConstructor();
  factory KujiRepository() => _instance;

  final List<KujiStatus> _shops = [
    KujiStatus(
      shopName: 'ローソン',
      kujiName: 'ワンピース 一番くじ',
      prizeA: 2,
      prizeB: 5,
      prizeC: 15,
      latitude: 35.633358,
      longitude: 139.716588,
    ),
    KujiStatus(
      shopName: 'ファミリーマート',
      kujiName: 'ポケモンくじ',
      prizeA: 3,
      prizeB: 6,
      prizeC: 12,
      latitude: 35.633858,
      longitude: 139.717088,
    ),
    KujiStatus(
      shopName: 'セブンイレブン',
      kujiName: 'お菓子くじ',
      prizeA: 4,
      prizeB: 8,
      prizeC: 20,
      latitude: 35.632858,
      longitude: 139.716088,
    ),
  ];

  List<KujiStatus> get shops => List.unmodifiable(_shops);

  KujiStatus? findByShopName(String name) {
    for (final shop in _shops) {
      if (shop.shopName == name) {
        return shop;
      }
    }
    return null;
  }

  void decrementPrize(String shopName, String prizeType) {
    final shop = findByShopName(shopName);
    if (shop == null) return;

    switch (prizeType) {
      case 'A':
        if (shop.prizeA > 0) shop.prizeA--;
        break;
      case 'B':
        if (shop.prizeB > 0) shop.prizeB--;
        break;
      case 'C':
        if (shop.prizeC > 0) shop.prizeC--;
        break;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'shops': _shops.map((s) => s.toJson()).toList(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  void loadFromJsonString(String jsonString) {
    final data = jsonDecode(jsonString);
    if (data is Map<String, dynamic> && data['shops'] is List) {
      _shops.clear();
      for (final item in data['shops']) {
        if (item is Map<String, dynamic>) {
          _shops.add(KujiStatus.fromJson(item));
        }
      }
    }
  }
}
