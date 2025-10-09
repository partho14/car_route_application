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
      destination: destination,
      polyline: polyline ?? this.polyline,
      routeData: routeData,
      isSelectingOrigin: isSelectingOrigin ?? this.isSelectingOrigin,
    );
  }
}

class MapNotifier extends AsyncNotifier<MapState> {
  @override
  Future<MapState> build() async {
    return MapState();
  }

  void selectPoint(LatLng latLng) {
    if (state.value == null) return;

    final currentState = state.value!;

    if (currentState.isSelectingOrigin) {
      state = AsyncValue.data(
        currentState.copyWith(
          origin: latLng,
          destination: null,
          polyline: [],
          routeData: null,
          isSelectingOrigin: false,
        ),
      );
    } else {
      state = AsyncValue.data(
        currentState.copyWith(destination: latLng, isSelectingOrigin: true),
      );
      _calculateRoute(currentState.origin!, latLng);
    }
  }

  void clearPoints() {
    state = AsyncValue.data(MapState(isSelectingOrigin: true));
  }

  Future<void> _calculateRoute(LatLng origin, LatLng destination) async {
    final routingService = RoutingService();

    try {
      state = AsyncValue<MapState>.loading().copyWithPrevious(state);

      final data = await routingService.calculateRoute(origin, destination);

      // Set successful data state
      state = AsyncValue.data(
        state.value!.copyWith(
          polyline: data.polyline,
          routeData: data,
          destination: destination,
          isSelectingOrigin: true,
        ),
      );
    } catch (e, st) {
      state = AsyncValue<MapState>.error(e, st).copyWithPrevious(state);

      state = AsyncValue.data(state.value!.copyWith(isSelectingOrigin: false));
    }
  }
}

final mapProvider = AsyncNotifierProvider<MapNotifier, MapState>(() {
  return MapNotifier();
});
