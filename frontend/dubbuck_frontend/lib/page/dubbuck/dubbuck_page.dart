import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import '../../services/jpsB_algorithm/jpsB_algorithm.dart';

class DubbuckPage extends StatefulWidget {
  @override
  _DubbuckPageState createState() => _DubbuckPageState();
}

class _DubbuckPageState extends State<DubbuckPage> {
  Completer<GoogleMapController> _controller = Completer();
  List<LatLng> _route = [];
  LatLng? _start;
  LatLng? _goal;

  static final LatLngBounds _sanFranciscoBounds = LatLngBounds(
    southwest: LatLng(37.703399, -122.527000),
    northeast: LatLng(37.812303, -122.348211),
  );

  static final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.7749, -122.4194), // 샌프란시스코 위치
    zoom: 14.0,
  );

  List<List<int>> grid = [
    [0, 1, 0, 0, 0],
    [0, 1, 0, 1, 0],
    [0, 0, 0, 1, 0],
    [1, 1, 0, 1, 0],
    [0, 0, 0, 0, 0]
  ];

  Point<int> toGridPoint(LatLng latLng) {
    return Point<int>(((latLng.latitude - 37.7749) * 1000).round(), ((latLng.longitude + 122.4194) * 1000).round());
  }

  LatLng toLatLng(Point<int> point) {
    return LatLng(37.7749 + point.x * 0.001, -122.4194 + point.y * 0.001);
  }

  Future<void> _setMapStyle() async {
    final controller = await _controller.future;
    String style = await rootBundle.loadString('assets/map_style.json');
    controller.setMapStyle(style);
  }

  void _calculateRoute() {
    if (_start != null && _goal != null) {
      Point<int> start = toGridPoint(_start!);
      Point<int> goal = toGridPoint(_goal!);
      List<Point<int>> path = jpsB(start, goal, grid);
      setState(() {
        _route = path.map((p) => toLatLng(p)).toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('JPS Navigation'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) async {
              _controller.complete(controller);
              await _setMapStyle();
              await controller.animateCamera(CameraUpdate.newLatLngBounds(_sanFranciscoBounds, 0));
            },
            onTap: (LatLng latLng) {
              setState(() {
                if (_start == null) {
                  _start = latLng;
                } else if (_goal == null) {
                  _goal = latLng;
                } else {
                  _start = latLng;
                  _goal = null;
                  _route = [];
                }
              });
            },
            markers: {
              if (_start != null) Marker(markerId: MarkerId('start'), position: _start!),
              if (_goal != null) Marker(markerId: MarkerId('goal'), position: _goal!),
            },
            polylines: _route.isNotEmpty
                ? {
              Polyline(
                polylineId: PolylineId('route'),
                points: _route,
                color: Colors.blue,
                width: 5,
              )
            }
                : {},
            mapToolbarEnabled: false,
            myLocationEnabled: false,
            compassEnabled: false,
            zoomControlsEnabled: false,
            minMaxZoomPreference: MinMaxZoomPreference(10.0, 18.0),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: ElevatedButton(
              onPressed: _calculateRoute,
              child: Text('Calculate Route'),
            ),
          ),
        ],
      ),
    );
  }
}
