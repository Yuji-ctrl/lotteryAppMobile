import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/kuji_status.dart';
import 'tabs/map_tab.dart';
import 'tabs/list_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  // 全店舗の在庫データをリストで保持
class _HomePageState extends State<HomePage> {
  // 全店舗の在庫データをリストで保持（現在地から半径500m以内に配置）
  final List<KujiStatus> _allShops = [
    KujiStatus(
      shopName: 'ローソン',
      kujiName: 'ワンピース 一番くじ',
      latitude: 35.8725,
      longitude: 139.7915,
    ),
    KujiStatus(
      shopName: 'ファミリーマート',
      kujiName: 'ポケモンくじ',
      prizeA: 2,
      prizeB: 5,
      prizeC: 15,
      latitude: 35.8680,
      longitude: 139.7905,
    ),
    KujiStatus(
      shopName: 'セブンイレブン',
      kujiName: 'お菓子くじ',
      prizeA: 5,
      prizeB: 10,
      prizeC: 30,
      latitude: 35.8700,
      longitude: 139.7860,
    ),
  ];

  Position? _currentPosition;
  final MapController _mapController = MapController();
  late TabController _tabController;
  StreamSubscription<Position>? _positionSubscription;
  List<KujiStatus> _nearbyShops = [];
  static const double _nearbyRadiusMeters = 500;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nearbyShops = List<KujiStatus>.from(_allShops);
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
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
      _currentPosition = await Geolocator.getCurrentPosition();
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
                _mapController.camera.zoom,
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

  void _handleMarkerTap(KujiStatus shop) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${shop.shopName}\n${shop.kujiName}')),
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('近くのコンビニ'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map), text: 'マップ'),
            Tab(icon: Icon(Icons.list), text: 'リスト'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // マップ操作との干渉を防ぐ
        children: [
          // マップタブ
          MapTab(
            shops: _nearbyShops,
            currentPosition: _currentPosition,
            mapController: _mapController,
            onMarkerTap: _handleMarkerTap,
          ),
          // リストタブ
          ListTab(
            shops: _nearbyShops,
            onRefresh: () {
              setState(() {});
            },
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
                  userAgentPackageName: 'com.example.app',
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
