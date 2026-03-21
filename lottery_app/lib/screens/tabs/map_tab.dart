import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/kuji_status.dart';

class MapTab extends StatelessWidget {
  final List<KujiStatus> shops;
  final Position? currentPosition;
  final MapController mapController;
  final Function(KujiStatus) onMarkerTap;

  const MapTab({
    super.key,
    required this.shops,
    required this.currentPosition,
    required this.mapController,
    required this.onMarkerTap,
  });

  @override
  Widget build(BuildContext context) {
    final initialCenter = currentPosition != null
        ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
        : const LatLng(35.6339, 139.7036);
    
    final nearbyRadiusMeters = 500.0;

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: initialCenter,
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        if (currentPosition != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
                color: Colors.blue.withAlpha(38),
                borderStrokeWidth: 2,
                borderColor: Colors.blue,
                useRadiusInMeter: true,
                radius: nearbyRadiusMeters,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            // 現在位置
            if (currentPosition != null)
              Marker(
                point: LatLng(currentPosition!.latitude, currentPosition!.longitude),
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
            ...shops.map((shop) {
              return Marker(
                point: LatLng(shop.latitude, shop.longitude),
                child: GestureDetector(
                  onTap: () => onMarkerTap(shop),
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
    );
  }
}
