import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class SeongkeumPage extends StatefulWidget {
  @override
  _SeongkeumPageState createState() => _SeongkeumPageState();
}

class _SeongkeumPageState extends State<SeongkeumPage> {
  static const String apiKey = 'YOUR_SERVICE_KEY';
  static const String apiUrl = 'http://openapi.forest.go.kr/openapi/service/trailInfoService/getforeststoryservice';

  List<Mountain> mountains = [];
  List<Mountain> filteredMountains = [];
  bool isLoading = true;
  String searchQuery = "";
  final _searchBarController = TextEditingController();
  final _btnClearController = StreamController<bool>();
  final _searchDebouncer = Debouncer(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error('Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition();
    fetchMountains(position.latitude, position.longitude);
  }

  Future<void> fetchMountains(double latitude, double longitude) async {
    final response = await http.get(Uri.parse('$apiUrl?ServiceKey=$apiKey&pageNo=1&numOfRows=10&latitude=$latitude&longitude=$longitude'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        mountains = (data['response']['body']['items'] as List)
            .map((item) => Mountain.fromJson(item))
            .toList();
        filteredMountains = mountains;
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load mountains');
    }
  }

  void filterSearchResults(String query) {
    List<Mountain> searchResult = [];
    if (query.isNotEmpty) {
      mountains.forEach((item) {
        if (item.name.contains(query) || item.location.contains(query)) {
          searchResult.add(item);
        }
      });
      setState(() {
        filteredMountains = searchResult;
      });
    } else {
      setState(() {
        filteredMountains = mountains;
      });
    }
  }

  @override
  void dispose() {
    _btnClearController.close();
    _searchBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('성급성급'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              height: 40,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: Colors.grey, size: 20),
                  SizedBox(width: 5),
                  Expanded(
                    child: TextFormField(
                      textInputAction: TextInputAction.search,
                      controller: _searchBarController,
                      onChanged: (value) {
                        _searchDebouncer.run(() {
                          if (value.isNotEmpty) {
                            _btnClearController.add(true);
                            setState(() {
                              searchQuery = value;
                            });
                          } else {
                            _btnClearController.add(false);
                            setState(() {
                              searchQuery = "";
                            });
                          }
                          filterSearchResults(searchQuery);
                        });
                      },
                      decoration: InputDecoration.collapsed(
                        hintText: '산 이름을 입력하세요',
                        hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  StreamBuilder<bool>(
                    stream: _btnClearController.stream,
                    builder: (_, snapshot) {
                      return snapshot.data == true
                          ? GestureDetector(
                          onTap: () {
                            _searchBarController.clear();
                            _btnClearController.add(false);
                            setState(() {
                              searchQuery = "";
                            });
                            filterSearchResults(searchQuery);
                          },
                          child: Icon(Icons.clear_rounded, color: Colors.grey, size: 20))
                          : SizedBox.shrink();
                    },
                  ),
                ],
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.grey[200],
              ),
              padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
              margin: EdgeInsets.fromLTRB(16, 8, 16, 8),
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: filteredMountains.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Icon(Icons.terrain),
                  title: Text(filteredMountains[index].name),
                  subtitle: Text('${filteredMountains[index].location} - ${filteredMountains[index].height}m'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Debouncer {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    if (_timer != null) {
      _timer?.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

void main() {
  runApp(MaterialApp(
    home: SeongkeumPage(),
  ));
}
