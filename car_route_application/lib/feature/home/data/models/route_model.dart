import 'package:latlong2/latlong.dart';

class RouteData {
  final double distanceMeters;
  final int durationSeconds;
  final List<LatLng> polyline;

  RouteData({
    required this.distanceMeters,
    required this.durationSeconds,
    required this.polyline,
  });

  String get formattedDistance {
    final km = distanceMeters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  String get formattedTime {
    final minutes = (durationSeconds / 60).round();
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = (minutes / 60).floor();
    final remainingMinutes = minutes % 60;
    return '$hours hr $remainingMinutes min';
  }

  factory RouteData.fromGoogleMaps(Map<String, dynamic> json) {
    if (json['routes'] == null || json['routes'].isEmpty) {
      throw Exception('No routes found by Google Maps API.');
    }

    final route = json['routes'][0];

    final leg = route['legs'][0];
    final distance = (leg['distance']['value'] as num).toDouble();
    final duration = leg['duration']['value'] as int;

    final polylineString = route['overview_polyline']['points'] as String;
    final decodedPolyline = decodePolyline(polylineString);

    return RouteData(
      distanceMeters: distance,
      durationSeconds: duration,
      polyline: decodedPolyline,
    );
  }

  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int byte;

      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        byte = encoded.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
      } while (byte >= 0x20);

      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return points;
  }
}
