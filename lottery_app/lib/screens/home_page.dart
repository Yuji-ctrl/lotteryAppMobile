import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/kuji_status.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 全店舗の在庫データをリストで保持（現在地から半径500m以内に配置）
  List<KujiStatus> _allShops = [];

  List<KujiStatus> _generateNearbyShops(Position current) {
    // 現在地を中心に約200m前後の仮想コンビニを3つ配置（すべて500m以内）
    return [
      KujiStatus(
        shopName: 'ローソン',
        kujiName: 'ワンピース 一番くじ',
        latitude: current.latitude + 0.0016, // 約180m
        longitude: current.longitude + 0.0012, // 約120m
      ),
      KujiStatus(
        shopName: 'ファミリーマート',
        kujiName: 'ポケモンくじ',
        prizeA: 2,
        prizeB: 5,
        prizeC: 15,
        latitude: current.latitude - 0.0012, // 約135m
        longitude: current.longitude + 0.0009, // 約100m
      ),
      KujiStatus(
        shopName: 'セブンイレブン',
        kujiName: 'お菓子くじ',
        prizeA: 5,
        prizeB: 10,
        prizeC: 30,
        latitude: current.latitude + 0.0008, // 約90m
        longitude: current.longitude - 0.0010, // 約110m
      ),
    ];
  }

  Position? _currentPosition;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSubscription;
  List<KujiStatus> _nearbyShops = [];
  static const double _nearbyRadiusMeters = 500;

  @override
  void initState() {
    super.initState();
    _nearbyShops = List<KujiStatus>.from(_allShops);
    _loadCurrentLocation();
  }

  void _updateNearbyShops() {
    if (_currentPosition == null) {
      _nearbyShops = List<KujiStatus>.from(_allShops);
      return;
    }

    _nearbyShops = _allShops.where((shop) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        shop.latitude,
        shop.longitude,
      );
      return distance <= _nearbyRadiusMeters;
    }).toList();

    if (_nearbyShops.isEmpty) {
      // 一定距離内に無ければ、全店を表示(ユーザに選択肢を提供)
      _nearbyShops = List<KujiStatus>.from(_allShops);
    }
  }

  Future<void> _loadCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 60),
      );

      if (_currentPosition != null) {
        _allShops = _generateNearbyShops(_currentPosition!);
      }

      _updateNearbyShops();

      // 初回取得時に地図を現在地へ移動
      if (_currentPosition != null) {
        _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15,
        );
      }

      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: 20,
            ),
          ).listen((position) {
            setState(() {
              _currentPosition = position;
              _updateNearbyShops();
              _mapController.move(
                LatLng(position.latitude, position.longitude),
                _mapController.zoom,
              );
            });
          });

      setState(() {});
    } else {
      // 位置情報の権限がない場合
      _nearbyShops = List<KujiStatus>.from(_allShops);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(35.6339, 139.7036);

    return Scaffold(
      appBar: AppBar(title: const Text('近くのコンビニ')),
      body: Column(
        children: [
          SizedBox(
            height: 250,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.yourname.kujimap',
                ),
                if (_currentPosition != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        color: Colors.blue.withOpacity(0.15),
                        borderStrokeWidth: 2,
                        borderColor: Colors.blue,
                        useRadiusInMeter: true,
                        radius: _nearbyRadiusMeters,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    // 現在位置
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          width: 20,
                          height: 20,
                        ),
                      ),
                    // 店舗マーカー
                    ..._nearbyShops.map((shop) {
                      return Marker(
                        point: LatLng(shop.latitude, shop.longitude),
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${shop.shopName}\n${shop.kujiName}',
                                ),
                              ),
                            );
                          },
                          child: Icon(
                            Icons.location_on,
                            color: shop.isSoldOut ? Colors.grey : Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _nearbyShops.length,
              itemBuilder: (context, index) {
                final shop = _nearbyShops[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  color: shop.isSoldOut ? Colors.grey[300] : Colors.white,
                  child: ListTile(
                    title: Text(
                      shop.shopName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '開催中：${shop.kujiName}${shop.isSoldOut ? " (完売)" : ""}',
                    ),
                    trailing: ElevatedButton(
                      onPressed: shop.isSoldOut
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      KujiDetailPage(status: shop),
                                ),
                              );
                              setState(() {});
                            },
                      child: Text(shop.isSoldOut ? '完売' : 'くじを見る'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}