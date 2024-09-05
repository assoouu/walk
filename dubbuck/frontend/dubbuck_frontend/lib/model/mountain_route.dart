import 'dart:convert';

class MountainRoute {
  final String name;
  final double sectionLength;
  final int upTime;
  final int downTime;
  final String difficulty;
  final List<Coordinate> coordinates;

  MountainRoute({
    required this.name,
    required this.sectionLength,
    required this.upTime,
    required this.downTime,
    required this.difficulty,
    required this.coordinates,
  });

  factory MountainRoute.fromMap(Map<String, dynamic> map) {
    final coordinatesJson = map['coordinates'] as String;
    final coordinatesList = json.decode(coordinatesJson) as List;
    List<Coordinate> coordinates = coordinatesList.map((coord) {
      return Coordinate(
        latitude: coord['latitude'],
        longitude: coord['longitude'],
      );
    }).toList();

    return MountainRoute(
      name: map['trail_name'] as String,
      sectionLength: map['trail_length'] as double,
      upTime: map['trail_up_time'] as int,
      downTime: map['trail_down_time'] as int,
      difficulty: map['trail_difficulty'] as String,
      coordinates: coordinates,
    );
  }
}

class Coordinate {
  final double latitude;
  final double longitude;

  Coordinate({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'Coordinate(latitude: $latitude, longitude: $longitude)';
  }
}
