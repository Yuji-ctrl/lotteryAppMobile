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
  // 全店舗の在庫データをリストで保持
  final List<KujiStatus> _allShops = [
    KujiStatus(shopName: 'ローソン', kujiName: 'ワンピース 一番くじ', latitude: 35.8738, longitude: 139.7955),
    KujiStatus(shopName: 'ファミリーマート', kujiName: 'ポケモンくじ', prizeA: 2, prizeB: 5, prizeC: 15, latitude: 35.8712, longitude: 139.7945),
    KujiStatus(shopName: 'セブンイレブン', kujiName: 'お菓子くじ', prizeA: 5, prizeB: 10, prizeC: 30, latitude: 35.8750, longitude: 139.7970),
  ];

  Position? _currentPosition;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : LatLng(35.8738, 139.7955);

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
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: [
                    // 現在位置
                    if (_currentPosition != null)
                      Marker(
                        point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
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
                    ..._allShops.map((shop) {
                      return Marker(
                        point: LatLng(shop.latitude, shop.longitude),
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${shop.shopName}\n${shop.kujiName}')),
                            );
                          },
                          child: Icon(
                            Icons.location_on,
                            color: shop.isSoldOut ? Colors.grey : Colors.red,
                            size: 40,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
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