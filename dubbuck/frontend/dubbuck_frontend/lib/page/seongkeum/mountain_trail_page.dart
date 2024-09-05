import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../model/mountain_information.dart';
import '../../model/mountain_route.dart';
import '../../service/mountain_trail_service.dart';

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
  final MountainTrailService _trailService = MountainTrailService();

  @override
  void initState() {
    super.initState();
    _initializeDatabaseAndFetchTrailInfo();
  }

  Future<void> _initializeDatabaseAndFetchTrailInfo() async {
    await _trailService.initializeDatabase();
    await _fetchTrailInfo();
  }

  Future<void> _fetchTrailInfo() async {
    try {
      final routes = await _trailService.fetchTrailInfo(widget.mountain.name);
      setState(() {
        _routes = routes;
        _polylineCoordinates = routes.expand((route) =>
            route.coordinates.map((coord) => LatLng(coord.latitude, coord.longitude))
        ).toList();
        print('Polyline coordinates: $_polylineCoordinates'); // 디버깅 로그 추가
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
                zoom: 11,
              ),
              polylines: _polylineCoordinates.isNotEmpty ? {
                Polyline(
                  polylineId: PolylineId('trail_polyline'),
                  color: Colors.blue,
                  width: 5,
                  points: _polylineCoordinates,
                ),
              } : {},
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

  @override
  void dispose() {
    _trailService.closeDatabase();
    super.dispose();
  }
}
