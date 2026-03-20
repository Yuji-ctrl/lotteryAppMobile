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
          ),
        ],
      ),
    );
  }
}
