import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DubbuckPage extends StatefulWidget {
  @override
  _DubbuckPageState createState() => _DubbuckPageState();
}

class _DubbuckPageState extends State<DubbuckPage> {
  GoogleMapController? _controller;
  Set<Marker> _markers = Set(); // 지도에 표시될 마커 집합
  LatLng _initialPosition = LatLng(37.77493, -122.41942); // 초기 위치 (샌프란시스코)
  bool _markersVisible = false; // 마커 표시 여부를 제어하는 변수
  Set<Polygon> _polygons = Set(); // 섹터를 나타내는 폴리곤 집합

  @override
  void initState() {
    super.initState();
    _determinePosition(); // 사용자의 현재 위치를 결정하는 함수 호출
  }

  // 사용자의 위치 서비스 활성화 및 위치 권한 확인
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 위치 서비스 활성화 확인
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('위치 서비스가 비활성화되어 있습니다.');
    }

    // 위치 권한 확인 및 요청
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('위치 권한이 거부되었습니다.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('위치 권한이 영구적으로 거부되어 권한 요청이 불가능합니다.');
    }

    // 현재 위치 가져오기
    Position position = await Geolocator.getCurrentPosition();
    setState(() {
      _initialPosition = LatLng(position.latitude, position.longitude);
      _controller?.animateCamera(CameraUpdate.newLatLng(_initialPosition));
      _fetchCCTVData();
    });
  }

  // API를 사용하여 모든 CCTV 데이터를 가져오는 함수
  Future<void> _fetchCCTVData() async {
    final String cctvApiKey = dotenv.env['CCTV_API_KEY']!;
    const int pageSize = 1000; // 한 페이지의 최대 데이터 수
    int pageIndex = 1;
    bool moreData = true;

    while (moreData) {
      final String url = 'https://openapi.gg.go.kr/CCTV?KEY=$cctvApiKey&Type=json&pIndex=$pageIndex&pSize=$pageSize';

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List cctvList = data['CCTV'][1]['row'];

          if (cctvList.isNotEmpty) {
            setState(() {
              _markers.addAll(_processCCTVData(cctvList));
              _createPolygons();
            });

            pageIndex++; // 다음 페이지 인덱스 증가
          } else {
            moreData = false; // 더 이상 불러올 데이터가 없으면 반복 중단
          }
        } else {
          print('Failed to load CCTV data');
          moreData = false; // 응답 실패시 반복 중단
        }
      } catch (e) {
        print('Error fetching CCTV data: $e');
        moreData = false; // 예외 발생시 반복 중단
      }
    }
  }

  // CCTV 데이터를 처리하여 마커를 생성하는 함수
  Set<Marker> _processCCTVData(List cctvList) {
    Set<Marker> markers = Set();

    for (var item in cctvList) {
      try {
        double latitude = double.parse(item['REFINE_WGS84_LAT']);
        double longitude = double.parse(item['REFINE_WGS84_LOGT']);
        String description = item['INSTL_PUPRS_DIV_NM'];

        double distance = Geolocator.distanceBetween(
            _initialPosition.latitude, _initialPosition.longitude, latitude, longitude
        );

        BitmapDescriptor markerColor;
        if (distance <= 500) {
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
        } else if (distance <= 1000) {
          markerColor = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
        } else {
          continue; // 1km 이상인 경우 마커를 표시하지 않음
        }

        markers.add(Marker(
          markerId: MarkerId('cctv_${item['REFINE_WGS84_LAT']}_${item['REFINE_WGS84_LOGT']}'),
          position: LatLng(latitude, longitude),
          icon: markerColor,
          infoWindow: InfoWindow(title: description, snippet: item['REFINE_ROADNM_ADDR']),
        ));
      } catch (e) {
        print('Error parsing CCTV item: $e');
      }
    }

    return markers;
  }

  // 각도를 기준으로 폴리곤을 생성하는 함수
  void _createPolygons() {
    // 섹터를 나눌 각도 (30도)
    const double sectorAngle = 30.0;
    List<Color> sectorColors = [Colors.red.withOpacity(0.5), Colors.green.withOpacity(0.5), Colors.blue.withOpacity(0.5), Colors.yellow.withOpacity(0.5)];

    for (int i = 0; i < 360 / sectorAngle; i++) {
      double startAngle = i * sectorAngle;
      double endAngle = (i + 1) * sectorAngle;
      Color color = sectorColors[i % sectorColors.length];

      List<LatLng> sectorVertices = _calculateSectorVertices(startAngle, endAngle);
      _polygons.add(Polygon(
        polygonId: PolygonId('sector_$i'),
        points: sectorVertices,
        fillColor: color,
        strokeColor: color,
        strokeWidth: 1,
        consumeTapEvents: true,
        onTap: () {
          print('Sector $i tapped');
        },
      ));
    }
  }

  // 섹터의 꼭지점을 계산하는 함수
  List<LatLng> _calculateSectorVertices(double startAngle, double endAngle) {
    List<LatLng> vertices = [];
    const double radius = 1000; // 섹터의 반지름 (1km)

    vertices.add(_initialPosition);

    for (double angle = startAngle; angle <= endAngle; angle += 1.0) {
      double radian = angle * (pi / 180);
      double latitude = _initialPosition.latitude + (radius / 111000) * cos(radian);
      double longitude = _initialPosition.longitude + (radius / (111000 * cos(_initialPosition.latitude * pi / 180))) * sin(radian);
      vertices.add(LatLng(latitude, longitude));
    }

    vertices.add(_initialPosition);

    return vertices;
  }

  // 마커의 표시 여부를 토글하는 함수
  void _toggleMarkers() {
    setState(() {
      _markersVisible = !_markersVisible;
    });
  }

  // 현재 위치로 지도 이동
  void _goToCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition();
    _controller?.animateCamera(CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)));
  }

  // Google Map 생성 시 호출되는 콜백
  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _controller?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, 14.0));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: _initialPosition,
              zoom: 14.0,
            ),
            markers: _markersVisible ? _markers : Set(),
            polygons: _polygons,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              children: [
                FloatingActionButton(
                  onPressed: _toggleMarkers,
                  child: Icon(Icons.visibility),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  onPressed: _goToCurrentLocation,
                  child: Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}