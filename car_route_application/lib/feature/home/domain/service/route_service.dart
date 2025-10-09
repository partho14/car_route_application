import 'dart:convert';
import 'package:car_route_application/feature/home/data/models/route_model.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  static const String apiKey = 'AIzaSyCnzZrqOV67s2k76lLy4B0DPkihPyGZsbE';
  static const String apiUrl =
      'https://maps.googleapis.com/maps/api/directions/json';

  Future<RouteData> calculateRoute(LatLng origin, LatLng destination) async {
    final originStr = '${origin.latitude},${origin.longitude}';
    final destinationStr = '${destination.latitude},${destination.longitude}';

    final uri = Uri.parse(
      '$apiUrl?origin=$originStr&destination=$destinationStr&mode=driving&key=$apiKey',
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final status = json['status'] as String;
      if (status != 'OK') {
        throw Exception(
          'Google Maps API Status: $status. Message: ${json['error_message'] ?? 'Check API key or billing.'}',
        );
      }

      return RouteData.fromGoogleMaps(json);
    } else {
      throw Exception(
        'Failed to load route from server. Status code: ${response.statusCode}',
      );
    }
  }
}
