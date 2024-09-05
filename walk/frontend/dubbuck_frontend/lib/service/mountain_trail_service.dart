import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../model/mountain_route_model.dart';

class MountainTrailService {
  final String apiKey = dotenv.env['TRAIL_API_KEY']!;
  final String domain = dotenv.env['YOUR_DOMAIN']!;

  Future<List<MountainRoute>> fetchTrailInfo({
    required String mountainName,
    required String geomFilter,
    required String attrFilter,
  }) async {
    final url =
        'https://api.vworld.kr/req/data?service=data&request=GetFeature&data=LT_L_FRSTCLIMB&key=$apiKey&domain=$domain&attrFilter=$attrFilter&geomFilter=$geomFilter&crs=EPSG:900913';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final document = xml.XmlDocument.parse(response.body);
      final items = document.findAllElements('item');

      if (items.isEmpty) {
        throw Exception('No items found in response');
      }

      return items.map((item) => MountainRoute.fromXml(item)).toList();
    } else {
      throw Exception('Failed to load trail info');
    }
  }
}
