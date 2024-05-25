import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:xml/xml.dart' as xml;
import '../model/mountain_model.dart';

class MountainService {
  Future<List<Mountain>> fetchMountains(double latitude, double longitude) async {
    final apiKey = dotenv.env['FOREST_API_KEY'];
    final url =
        'http://openapi.forest.go.kr/openapi/service/trailInfoService/getforeststoryservice?ServiceKey=$apiKey&pageNo=1&numOfRows=10&latitude=$latitude&longitude=$longitude';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');
        return items.map((item) => Mountain.fromXml(item)).toList();
      } else {
        throw Exception('Failed to load mountains');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
