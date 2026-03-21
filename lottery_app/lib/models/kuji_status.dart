class KujiStatus {
  final String shopName;
  final String kujiName;
  int prizeA;
  int prizeB;
  int prizeC;
  final double latitude;
  final double longitude;

  bool get isSoldOut => prizeA == 0 && prizeB == 0 && prizeC == 0;

  KujiStatus({
    required this.shopName,
    required this.kujiName,
    this.prizeA = 0,
    this.prizeB = 0,
    this.prizeC = 0,
    required this.latitude,
    required this.longitude,
  });

  KujiStatus.fromJson(Map<String, dynamic> json)
      : shopName = json['shopName'] as String,
        kujiName = json['kujiName'] as String,
        prizeA = json['prizeA'] as int,
        prizeB = json['prizeB'] as int,
        prizeC = json['prizeC'] as int,
        latitude = (json['latitude'] as num).toDouble(),
        longitude = (json['longitude'] as num).toDouble();

  Map<String, dynamic> toJson() {
    return {
      'shopName': shopName,
      'kujiName': kujiName,
      'prizeA': prizeA,
      'prizeB': prizeB,
      'prizeC': prizeC,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}