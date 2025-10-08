import 'package:car_route_application/feature/home/data/models/route_model.dart';
import 'package:latlong2/latlong.dart';

class RoutingService {
  Future<(List<LatLng> polyline, RouteData routeData)> getRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    await Future.delayed(const Duration(seconds: 1));

    // Calculate rough midpoint for a curved mock polyline
    final midLat = (origin.latitude + destination.latitude) / 2;
    final midLon = (origin.longitude + destination.longitude) / 2;

    // Introduce a slight curve or deviation for a realistic look
    final curveLat = midLat + (destination.latitude - midLat) * 0.1;
    final curveLon = midLon + (destination.longitude - midLon) * 0.1;

    final mockPolyline = [origin, LatLng(curveLat, curveLon), destination];

    // Calculate a mock distance (using Haversine formula for rough estimation)
    const distance = Distance();
    final mockDistance = distance(origin, destination) / 1000; // in km

    // Estimate time (e.g., assuming average speed of 50 km/h)
    final mockTimeMinutes = (mockDistance / 50 * 60).round();

    final mockRouteData = RouteData(
      distanceKm: mockDistance,
      timeMinutes: mockTimeMinutes,
    );

    return (mockPolyline, mockRouteData);
  }
}
