import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../model/mountain_information.dart';
import '../../service/mountain_trail_service.dart';
import '../../model/mountain_route_model.dart';

class MountainTrailPage extends StatefulWidget {
  final Mountain mountain;

  MountainTrailPage({required this.mountain});

  @override
  _MountainTrailPageState createState() => _MountainTrailPageState();
}

class _MountainTrailPageState extends State<MountainTrailPage> {
  GoogleMapController? _mapController;
  List<LatLng> _polylineCoordinates = [];
  String _errorMessage = '';
  List<MountainRoute> _routes = [];

  @override
  void initState() {
    super.initState();
    _fetchTrailInfo();
  }

  Future<void> _fetchTrailInfo() async {
    final trailService = MountainTrailService();
    try {
      final routes = await trailService.fetchTrailInfo(
        mountainName: widget.mountain.name,
        geomFilter: 'LINESTRING(13133057.313802 4496529.073264,14133023.872602 4496514.7413212)',
        attrFilter: 'sec_len:BETWEEN:100,200',
      );
      setState(() {
        _routes = routes;
        _polylineCoordinates = routes.expand((route) =>
            route.coordinates.map((coord) => LatLng(coord.latitude, coord.longitude))
        ).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    }
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case '상':
        return Colors.red;
      case '중':
        return Colors.orange;
      case '하':
      default:
        return Colors.green;
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
          : Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(widget.mountain.latitude ?? 0.0, widget.mountain.longitude ?? 0.0),
                zoom: 14,
              ),
              polylines: _routes.map((route) => Polyline(
                polylineId: PolylineId(route.name),
                color: _getDifficultyColor(route.difficulty),
                width: 5,
                points: route.coordinates.map((coord) => LatLng(coord.latitude, coord.longitude)).toList(),
              )).toSet(),
              onMapCreated: (controller) {
                setState(() {
                  _mapController = controller;
                });
              },
            ),
          ),
          if (_routes.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _routes.length,
                itemBuilder: (context, index) {
                  final route = _routes[index];
                  return ListTile(
                    title: Text(route.name),
                    subtitle: Text(
                        '길이: ${route.sectionLength}m, 상행: ${route.upTime}분, 하행: ${route.downTime}분, 난이도: ${route.difficulty}'),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
