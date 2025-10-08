import 'package:car_route_application/feature/home/presentation/state/map_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends ConsumerWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapStateAsync = ref.watch(mapProvider);
    final mapNotifier = ref.read(mapProvider.notifier);

    const initialCenter = LatLng(23.766902, 90.358283);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Route Planner'),
        backgroundColor: Colors.blueAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Points',
            onPressed: mapNotifier.clearPoints,
          ),
        ],
      ),
      body: mapStateAsync.when(
        loading:
            () =>
                mapStateAsync.value == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildMapInterface(
                      context,
                      mapStateAsync.value!,
                      mapNotifier,
                      initialCenter,
                    ),
        error:
            (error, stack) => _buildErrorInterface(
              context,
              mapStateAsync.value,
              mapNotifier,
              error.toString(),
            ),
        data:
            (mapState) => _buildMapInterface(
              context,
              mapState,
              mapNotifier,
              initialCenter,
            ),
      ),
    );
  }

  Widget _buildMapInterface(
    BuildContext context,
    MapState mapState,
    MapNotifier mapNotifier,
    LatLng initialCenter,
  ) {
    final statusText =
        mapState.origin == null
            ? 'Tap to select Origin'
            : mapState.destination == null
            ? 'Tap to select Destination'
            : mapState.isSelectingOrigin
            ? 'Destination Set. Tap to set new Origin'
            : 'Origin Set. Tap to set new Destination';

    final isLoading =
        mapState.origin != null &&
        mapState.destination != null &&
        mapState.polyline.isEmpty &&
        mapState.routeData == null;

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 10.0,
            maxZoom: 18.0,
            onTap: (_, latlng) => mapNotifier.selectPoint(latlng),
          ),
          children: [
            // OpenStreetMap Tile Layer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.car_route_app',
            ),

            // Route Polyline Layer
            PolylineLayer(
              polylines: [
                if (mapState.polyline.isNotEmpty)
                  Polyline(
                    points: mapState.polyline,
                    strokeWidth: 5.0,
                    color: Colors.blue.shade700,
                  ),
              ],
            ),

            // Markers Layer
            MarkerLayer(
              markers: [
                if (mapState.origin != null)
                  Marker(
                    point: mapState.origin!,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 45.0,
                    ),
                  ),
                if (mapState.destination != null)
                  Marker(
                    point: mapState.destination!,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 45.0,
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Map Status Indicator
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: _buildStatusCard(context, statusText),
        ),

        // Route Info and Loading Indicator
        if (isLoading)
          const Positioned.fill(
            child: Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text(
                        'Calculating route...',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else if (mapState.routeData != null)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildRouteInfoCard(context, mapState),
          ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context, String text) {
    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfoCard(BuildContext context, MapState mapState) {
    return Card(
      elevation: 10,
      color: Colors.blueAccent.shade700,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Optimal Route Found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(color: Colors.white70, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoPill(
                  icon: Icons.access_time_filled,
                  label: 'Time',
                  value: mapState.routeData!.formattedTime,
                ),
                _buildInfoPill(
                  icon: Icons.route,
                  label: 'Distance',
                  value: mapState.routeData!.formattedDistance,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildErrorInterface(
    BuildContext context,
    MapState? mapState,
    MapNotifier mapNotifier,
    String error,
  ) {
    return Stack(
      children: [
        // Show the map if possible
        if (mapState != null)
          _buildMapInterface(
            context,
            mapState,
            mapNotifier,
            const LatLng(48.8566, 2.3522),
          ),

        // Error overlay
        Positioned.fill(
          child: Container(
            color: Colors.black54,
            child: Center(
              child: Card(
                color: Colors.white,
                margin: const EdgeInsets.all(30),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 50,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Route Calculation Error',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Details: $error. Please try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: mapNotifier.clearPoints,
                        child: const Text('Clear and Restart'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
