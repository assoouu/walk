import 'dart:convert';
import 'package:xml/xml.dart' as xml;

class Mountain {
  final String name;
  final String location;
  final String height;
  final String details;
  final String management;
  final String phone;
  final double? latitude;
  final double? longitude;

  Mountain({
    required this.name,
    required this.location,
    required this.height,
    required this.details,
    required this.management,
    required this.phone,
    this.latitude,
    this.longitude,
  });

  factory Mountain.fromXml(xml.XmlElement element) {
    return Mountain(
      name: element.findElements('mntiname').single.text,
      location: element.findElements('mntiadd').single.text,
      height: element.findElements('mntihigh').single.text,
      details: element.findElements('mntidetails').single.text,
      management: element.findElements('mntiadmin').single.text,
      phone: element.findElements('mntiadminnum').single.text,
    );
  }

  factory Mountain.fromJson(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    return Mountain(
      name: data['name'],
      location: data['location'],
      height: data['height'],
      details: data['details'],
      management: data['management'],
      phone: data['phone'],
      latitude: data['latitude'],
      longitude: data['longitude'],
    );
  }

  String toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'location': location,
      'height': height,
      'details': details,
      'management': management,
      'phone': phone,
      'latitude': latitude,
      'longitude': longitude,
    };
    return jsonEncode(data);
  }
}
