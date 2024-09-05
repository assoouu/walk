import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../model/mountain_information.dart';
import '../../service/mountain_service.dart';
import '../../utils/debouncer.dart';
import 'mountain_trail_page.dart';

class SeongkeumPage extends StatefulWidget {
  final double latitude;
  final double longitude;

  SeongkeumPage({required this.latitude, required this.longitude});

  @override
  _SeongkeumPageState createState() => _SeongkeumPageState();
}

class _SeongkeumPageState extends State<SeongkeumPage> {
  List<Mountain> mountains = [];
  List<Mountain> recentMountains = [];
  bool isLoading = false;
  String searchQuery = "";
  String errorMessage = "";
  final _searchBarController = TextEditingController();
  final _btnClearController = StreamController<bool>();
  final _searchDebouncer = Debouncer(milliseconds: 300);
  final MountainService mountainService = MountainService();
  bool isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _loadRecentMountains();
  }

  Future<void> fetchMountains(String searchWrd) async {
    setState(() {
      isLoading = true;
      isSearchActive = true;
    });
    try {
      final mountains = await mountainService.fetchMountains(searchWrd);
      setState(() {
        this.mountains = mountains;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching mountains: $e');
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  void filterSearchResults(String query) {
    _searchDebouncer.run(() {
      fetchMountains(query);
    });
  }

  Future<void> _loadRecentMountains() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? mountainStrings = prefs.getStringList('recentMountains');
    if (mountainStrings != null) {
      setState(() {
        recentMountains = mountainStrings.map((e) => Mountain.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveRecentMountain(Mountain mountain) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> mountainStrings = prefs.getStringList('recentMountains') ?? [];
    String mountainJson = mountain.toJson();

    // Remove the mountain if it already exists to avoid duplicates
    mountainStrings.removeWhere((item) => Mountain.fromJson(item).name == mountain.name);

    // Add the mountain to the beginning of the list
    mountainStrings.insert(0, mountainJson);

    // Save the updated list
    prefs.setStringList('recentMountains', mountainStrings);
    _loadRecentMountains(); // Update the recent mountains list
  }

  Future<void> _deleteRecentMountain(Mountain mountain) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> mountainStrings = prefs.getStringList('recentMountains') ?? [];
    String mountainJson = mountain.toJson();

    mountainStrings.remove(mountainJson);

    prefs.setStringList('recentMountains', mountainStrings);
    _loadRecentMountains(); // Update the recent mountains list
  }

  Future<void> _fetchAndShowMountainDetails(Mountain mountain) async {
    try {
      final location = await mountainService.fetchMountainLocation(mountain.name);
      final updatedMountain = Mountain(
        name: mountain.name,
        location: mountain.location,
        height: mountain.height,
        details: mountain.details,
        management: mountain.management,
        phone: mountain.phone,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      _showMountainDetails(updatedMountain);
    } catch (e) {
      print('Failed to fetch location for ${mountain.name}: $e');
      _showMountainDetails(mountain);
    }
  }

  void _showMountainDetails(Mountain mountain) {
    _saveRecentMountain(mountain);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mountain.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: ${mountain.location}'),
              Text('Height: ${mountain.height}m'),
              Text('Details: ${mountain.details}'),
              Text('Management: ${mountain.management}'),
              Text('Phone: ${mountain.phone}'),
              if (mountain.latitude != null && mountain.longitude != null) ...[
                Text('Latitude: ${mountain.latitude}'),
                Text('Longitude: ${mountain.longitude}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _navigateToMountainRoute(Mountain mountain) {
    _saveRecentMountain(mountain);
    if (mountain.latitude == null || mountain.longitude == null) {
      _fetchAndShowMountainDetails(mountain);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MountainTrailPage(mountain: mountain),
        ),
      );
    }
  }

  void _confirmDelete(Mountain mountain) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Confirmation'),
        content: Text('Are you sure you want to delete ${mountain.name}?'),
        actions: [
          TextButton(
            onPressed: () {
              _deleteRecentMountain(mountain);
              Navigator.of(context).pop();
            },
            child: Text('Delete'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
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
        title: Text('주변 산 정보'),
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
                              isSearchActive = false;
                            });
                          }
                        });
                      },
                      onFieldSubmitted: (value) {
                        filterSearchResults(value);
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
                            isSearchActive = false;
                          });
                        },
                        child: Icon(Icons.clear_rounded,
                            color: Colors.grey, size: 20),
                      )
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
          if (!isSearchActive && recentMountains.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '최근 검색된 산:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          if (!isSearchActive && recentMountains.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: recentMountains.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: IconButton(
                      icon: Icon(Icons.terrain),
                      onPressed: () =>
                          _fetchAndShowMountainDetails(recentMountains[index]),
                    ),
                    title: Text(recentMountains[index].name),
                    subtitle: Text(
                        '${recentMountains[index].location} - ${recentMountains[index].height}m'),
                    onTap: () => _navigateToMountainRoute(recentMountains[index]),
                    onLongPress: () =>
                        _confirmDelete(recentMountains[index]),
                  );
                },
              ),
            ),
          if (isSearchActive)
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : errorMessage.isNotEmpty
                  ? Center(child: Text(errorMessage))
                  : ListView.builder(
                itemCount: mountains.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: IconButton(
                      icon: Icon(Icons.terrain),
                      onPressed: () =>
                          _fetchAndShowMountainDetails(mountains[index]),
                    ),
                    title: Text(mountains[index].name),
                    subtitle: Text(
                        '${mountains[index].location} - ${mountains[index].height}m'),
                    onTap: () => _navigateToMountainRoute(mountains[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
