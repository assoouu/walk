import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import '../model/mountain_information.dart';

class MountainService {
  final String apiKey = dotenv.env['FOREST_API_KEY']!;

  Future<List<Mountain>> fetchMountains(String searchWrd) async {
    final url = 'http://apis.data.go.kr/1400000/service/cultureInfoService2/mntInfoOpenAPI2?serviceKey=$apiKey&searchWrd=$searchWrd&pageNo=1&numOfRows=10';
    print('Request URL: $url');

    final response = await http.get(Uri.parse(url), headers: {'Accept-Charset': 'utf-8'});
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(utf8.decode(response.bodyBytes));
      final items = document.findAllElements('item');

      if (items.isEmpty) {
        throw Exception('No items found in response');
      }

      List<Mountain> mountains = items.map((item) => Mountain.fromXml(item)).toList();

      for (int i = 0; i < mountains.length; i++) {
        try {
          final location = await fetchMountainLocation(mountains[i].name);
          mountains[i] = Mountain(
            name: mountains[i].name,
            location: mountains[i].location,
            height: mountains[i].height,
            details: mountains[i].details,
            management: mountains[i].management,
            phone: mountains[i].phone,
            latitude: location.latitude,
            longitude: location.longitude,
          );
        } catch (e) {
          print('Failed to fetch location for ${mountains[i].name}: $e');
        }
      }

      return mountains;
    } else {
      throw Exception('Failed to load mountains');
    }
  }

  Future<Mountain> fetchMountainLocation(String mountainName) async {
    final url = 'http://apis.data.go.kr/B553662/fmmtnFrtrlPoiInfoService/getFmmtnFrtrlPoiInfoList?serviceKey=$apiKey&pageNo=1&numOfRows=1&type=xml&srchFrtrlNm=$mountainName';
    print('Request URL: $url');

    final response = await http.get(Uri.parse(url));
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final item = document.findAllElements('item').first;

      return Mountain(
        name: mountainName,
        location: '',  // Location information is not required for location API
        height: '',    // Height information is not required for location API
        details: '',   // Details information is not required for location API
        management: '',// Management information is not required for location API
        phone: '',     // Phone information is not required for location API
        latitude: double.tryParse(item.findElements('lat').single.text),
        longitude: double.tryParse(item.findAllElements('lot').single.text),
      );
    } else {
      throw Exception('Failed to load mountain location');
    }
  }
}
