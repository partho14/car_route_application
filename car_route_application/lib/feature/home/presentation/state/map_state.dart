import 'package:car_route_application/feature/home/data/models/route_model.dart';
import 'package:car_route_application/feature/home/domain/service/route_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

class MapState {
  final LatLng? origin;
  final LatLng? destination;
  final List<LatLng> polyline;
  final RouteData? routeData;
  final bool isSelectingOrigin;

  MapState({
    this.origin,
    this.destination,
    this.polyline = const [],
    this.routeData,
    this.isSelectingOrigin = true,
  });

  MapState copyWith({
    LatLng? origin,
    LatLng? destination,
    List<LatLng>? polyline,
    RouteData? routeData,
    bool? isSelectingOrigin,
  }) {
    return MapState(
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      polyline: polyline ?? this.polyline,
      routeData: routeData ?? this.routeData,
      isSelectingOrigin: isSelectingOrigin ?? this.isSelectingOrigin,
    );
  }
}

class MapNotifier extends StateNotifier<AsyncValue<MapState>> {
  final RoutingService _routingService;

  MapNotifier(this._routingService) : super(AsyncValue.data(MapState()));

  void selectPoint(LatLng point) {
    state.whenData((mapState) async {
      LatLng? newOrigin = mapState.origin;
      LatLng? newDestination = mapState.destination;
      bool newIsSelectingOrigin = mapState.isSelectingOrigin;

      if (mapState.isSelectingOrigin || mapState.origin == null) {
        newOrigin = point;
        newDestination = null;
        newIsSelectingOrigin = false;
      } else {
        newDestination = point;
        newIsSelectingOrigin = true;
      }

      // Update state temporarily
      state = AsyncValue.data(
        mapState.copyWith(
          origin: newOrigin,
          destination: newDestination,
          polyline: [],
          routeData: null,
          isSelectingOrigin: newIsSelectingOrigin,
        ),
      );

      // Check if both points are set to calculate route
      if (newOrigin != null && newDestination != null) {
        // Check to prevent calculation if origin and destination are the same
        if (newOrigin.latitude == newDestination.latitude &&
            newOrigin.longitude == newDestination.longitude) {
          state = AsyncValue.data(
            state.value!.copyWith(isSelectingOrigin: true),
          );
          return;
        }

        await _calculateRoute(newOrigin, newDestination);
      }
    });
  }

  void clearPoints() {
    state = AsyncValue.data(MapState(isSelectingOrigin: true));
  }

  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    state = AsyncValue<MapState>.loading().copyWithPrevious(state);

    try {
      final (polyline, routeData) = await _routingService.getRoute(
        origin,
        destination,
      );

      state = AsyncValue.data(
        state.value!.copyWith(polyline: polyline, routeData: routeData),
      );
    } catch (e, st) {
      state = AsyncValue<MapState>.error(e, st).copyWithPrevious(state);
    }
  }
}

final routingServiceProvider = Provider((ref) => RoutingService());
final mapProvider = StateNotifierProvider<MapNotifier, AsyncValue<MapState>>((
  ref,
) {
  final routingService = ref.watch(routingServiceProvider);
  return MapNotifier(routingService);
});
