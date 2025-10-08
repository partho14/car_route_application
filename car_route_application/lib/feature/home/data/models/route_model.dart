import 'package:flutter/foundation.dart';

@immutable
class RouteData {
  final double distanceKm;
  final int timeMinutes;

  const RouteData({required this.distanceKm, required this.timeMinutes});

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedTime {
    if (timeMinutes < 60) {
      return '$timeMinutes min';
    }
    final hours = timeMinutes ~/ 60;
    final minutes = timeMinutes % 60;
    return '${hours}h ${minutes}min';
  }

  @override
  String toString() => 'Distance: $formattedDistance, Time: $formattedTime';
}
