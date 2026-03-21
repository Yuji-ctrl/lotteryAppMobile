import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:openapi/api.dart' show Store;
import '../models/kuji_status.dart';
import '../services/api_service.dart';
import 'detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _fallbackLatitude = 35.8738;
  static const double _fallbackLongitude = 139.7955;
  final ApiService _apiService = ApiService(
    storesBasePath: "https://dzqidy2gl8.execute-api.ap-northeast-1.amazonaws.com/Prod"
  );
  List<KujiStatus> _allShops = [];
  bool _isLoadingStores = true;
  String? _storesError;

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
    try {
      final permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        _currentPosition = await Geolocator.getCurrentPosition();
      }
    } catch (_) {
      // Continue with fallback coordinates when location cannot be obtained.
    } finally {
      if (mounted) {
        setState(() {});
      }
      await _loadStores();
    }
  }

  Future<void> _loadStores() async {
    setState(() {
      _isLoadingStores = true;
      _storesError = null;
    });

    try {
      final stores = await _apiService.fetchAllStores();
      if (kDebugMode) {
        print('fetchAllStores response count: ${stores.length}');
        for (final store in stores.take(5)) {
          print(
            'storeId=${store.storeId}, storeName=${store.storeName}, latitude=${store.latitude}, longitude=${store.longitude}',
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _allShops = stores.map(_toKujiStatus).toList(growable: false);
      });
    } catch (e) {
      print(e);
      if (!mounted) return;
      setState(() {
        _storesError = '店舗一覧の取得に失敗しました。通信環境を確認して再度お試しください。';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingStores = false;
      });
    }
  }

  KujiStatus _toKujiStatus(Store store) {
    return KujiStatus(
      storeId: store.storeId,
      shopName: store.storeName,
      kujiName: 'デジタル一番くじ',
      prizeA: 1,
      prizeB: 1,
      prizeC: 1,
      latitude: store.latitude,
      longitude: store.longitude,
    );
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
      : const LatLng(_fallbackLatitude, _fallbackLongitude);

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
            child: _isLoadingStores
                ? const Center(child: CircularProgressIndicator())
                : _storesError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _storesError!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _loadStores,
                              child: const Text('再試行'),
                            ),
                          ],
                        ),
                      )
                    : _allShops.isEmpty
                        ? const Center(child: Text('近隣の対象店舗が見つかりませんでした'))
                        : ListView.builder(
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
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(builder: (context) => KujiDetailPage(status: shop)),
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