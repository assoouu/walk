import 'package:xml/xml.dart' as xml;

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

  factory MountainRoute.fromXml(xml.XmlElement element) {
    return MountainRoute(
      name: element.findElements('mntn_nm').single.text,
      sectionLength: double.parse(element.findElements('sec_len').single.text),
      upTime: int.parse(element.findElements('up_min').single.text),
      downTime: int.parse(element.findElements('down_min').single.text),
      difficulty: element.findElements('cat_nam').single.text,
      coordinates: element.findElements('ag_geom').single.text
          .replaceAll('LINESTRING(', '')
          .replaceAll(')', '')
          .split(',')
          .map((coord) {
        final latLng = coord.split(' ');
        return Coordinate(
          latitude: double.parse(latLng[1]),
          longitude: double.parse(latLng[0]),
        );
      }).toList(),
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
}
