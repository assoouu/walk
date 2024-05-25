import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;

import '../../model/mountain_information.dart';
import '../../model/mountain_location.dart';

class MountainRoutePage extends StatefulWidget {
  final Mountain mountain;

  MountainRoutePage({required this.mountain});

  @override
  _MountainRoutePageState createState() => _MountainRoutePageState();
}

class _MountainRoutePageState extends State<MountainRoutePage> {
  GoogleMapController? _mapController;
  MountainLocation? _mountainLocation;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchMountainLocation();
  }

  Future<void> _fetchMountainLocation() async {
    final String apiKey = dotenv.env['FOREST_API_KEY']!;
    final url = 'http://apis.data.go.kr/B553662/fmmtnFrtrlPoiInfoService/getFmmtnFrtrlPoiInfoList?serviceKey=$apiKey&pageNo=1&numOfRows=1&type=xml&srchFrtrlNm=${widget.mountain.name}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final item = document.findAllElements('item').first;
        setState(() {
          _mountainLocation = MountainLocation.fromXml(item);
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load mountain location';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.mountain.name),
      ),
      body: _errorMessage.isNotEmpty
          ? Center(child: Text(_errorMessage))
          : _mountainLocation == null
          ? Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(_mountainLocation!.latitude, _mountainLocation!.longitude),
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: MarkerId('mountain'),
            position: LatLng(_mountainLocation!.latitude, _mountainLocation!.longitude),
            infoWindow: InfoWindow(title: widget.mountain.name),
          ),
        },
        onMapCreated: (controller) {
          setState(() {
            _mapController = controller;
          });
        },
      ),
    );
  }
}
