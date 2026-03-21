class KujiStatus {
  final String? storeId;
  final String shopName;
  final String kujiName;
  int prizeA;
  int prizeB;
  int prizeC;
  final double latitude;
  final double longitude;

  bool get isSoldOut => prizeA == 0 && prizeB == 0 && prizeC == 0;

  KujiStatus({
    this.storeId,
    required this.shopName,
    required this.kujiName,
    this.prizeA = 0,
    this.prizeB = 0,
    this.prizeC = 0,
    required this.latitude,
    required this.longitude,
  });
}