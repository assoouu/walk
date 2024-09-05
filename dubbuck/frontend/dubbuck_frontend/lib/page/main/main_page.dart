import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubbuck_front/constant/menu_settings.dart' as menu_constants;
import 'package:dubbuck_front/model/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../constant/color_constants.dart';
import '../../model/user_information.dart';
import '../../model/weather_data.dart';
import '../../providers/google_auth_provider.dart';
import '../../providers/kakao_auth_provider.dart';
import '../../providers/naver_auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../service/location_service.dart';
import '../../service/weather_service.dart';
import '../login/login_page.dart';
import '../settings_page.dart';
import 'airQuality_info.dart';
import 'custom_bottom_nav_bar.dart';
import 'daily_info_tiles.dart';
import 'weather_info.dart';
import '../../utils/skeleton_ui.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  Future<WeatherData>? futureWeatherData;
  Future<AirQualityData>? futureAirQualityData;
  Position? _currentPosition;
  bool? _isCheckedIn = false;
  DateTime? _lastCheckedInTime;

  UserInformation? _userInfo;
  late final _googleAuthProvider = context.read<AuthProviderGoogle>();
  late final _naverAuthProvider = context.read<AuthProviderNaver>();
  late final _kakaoAuthProvider = context.read<AuthProviderKakao>();
  final LocationService _locationService = LocationService();
  final WeatherService _weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    dotenv.load();
    _fetchLocationAndData();
    _fetchUserInfo();
    _loadCheckInStatus();
  }

  Future<void> _loadCheckInStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isCheckedIn = prefs.getBool('isCheckedIn');
    String? lastCheckedInTimeString = prefs.getString('lastCheckedInTime');

    if (isCheckedIn != null && lastCheckedInTimeString != null) {
      DateTime lastCheckedInTime = DateTime.parse(lastCheckedInTimeString);
      if (DateTime.now().difference(lastCheckedInTime).inMinutes >= 10) {
        isCheckedIn = false;
        lastCheckedInTime = DateTime.now();
        await prefs.setBool('isCheckedIn', false);
        await prefs.setString('lastCheckedInTime', lastCheckedInTime.toIso8601String());
      }

      setState(() {
        _isCheckedIn = isCheckedIn;
        _lastCheckedInTime = lastCheckedInTime;
      });
    } else {
      await prefs.setBool('isCheckedIn', false);
      await prefs.setString('lastCheckedInTime', DateTime.now().toIso8601String());
    }
  }

  Future<void> _checkIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isCheckedIn = true;
      _lastCheckedInTime = DateTime.now();
    });
    await prefs.setBool('isCheckedIn', true);
    await prefs.setString('lastCheckedInTime', _lastCheckedInTime!.toIso8601String());

    // Show GIF and message
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('축하합니다!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/출석체크.gif'),
            Text('포인트 1점을 획득하셨습니다!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchUserInfoById(String userId) async {
    try {
      DocumentSnapshot userInfoSnapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      print('Fetched user data: ${userInfoSnapshot.data()}');
      setState(() {
        _userInfo = UserInformation.fromDocument(userInfoSnapshot);
        print('_userInfo after fetching: ${_userInfo.toString()}');
      });
    } catch (e) {
      print('Error fetching user info by id: $e');
    }
  }


  Future<void> _fetchUserInfo() async {
    try {
      if (_googleAuthProvider.status == GoogleStatus.authenticated) {
        await _fetchUserInfoById(_googleAuthProvider.userFirebaseId ?? '');
      } else if (_naverAuthProvider.status == NaverStatus.authenticated) {
        await _fetchUserInfoById(_naverAuthProvider.userFirebaseId ?? '');
      } else if (_kakaoAuthProvider.status == KakaoStatus.authenticated) {
        await _fetchUserInfoById(_kakaoAuthProvider.userFirebaseId ?? '');
      }
      print('_userInfo: $_userInfo');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${'failed-to-fetch-user-information'.i18n()}: $e'),
      ));
    }
  }

  void _fetchLocationAndData() async {
    try {
      Position position = await _locationService.getCurrentLocation();
      setState(() {
        _currentPosition = position;
      });
      _fetchWeatherData(position);
      _fetchAirQualityData(position);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
  }

  void _fetchWeatherData(Position position) async {
    try {
      WeatherData weatherData = await _weatherService.fetchWeatherData(position.latitude, position.longitude);
      setState(() {
        futureWeatherData = Future.value(weatherData);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${'failed-to-fetch-weather-data'.i18n()}: $e'),
      ));
    }
  }

  void _fetchAirQualityData(Position position) async {
    try {
      AirQualityData airQualityData = await _weatherService.fetchAirQualityData(position.latitude, position.longitude);
      setState(() {
        futureAirQualityData = Future.value(airQualityData);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${'failed-to-fetch-air-quality-data'.i18n()}: $e'),
      ));
    }
  }

  void _updateWeatherAndAirQuality() {
    if (_currentPosition != null) {
      _fetchWeatherData(_currentPosition!);
      _fetchAirQualityData(_currentPosition!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${'location-not-available'.i18n()}'),
      ));
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemMenuPress(menu_constants.MenuSetting choice) {
    if (choice.title == 'log-out'.i18n()) {
      if (_googleAuthProvider.status == GoogleStatus.authenticated) {
        _handleGoogleSignOut();
      } else if (_naverAuthProvider.status == NaverStatus.authenticated) {
        _handleNaverSignOut();
      } else if (_kakaoAuthProvider.status == KakaoStatus.authenticated) {
        _handleKakaoSignOut();
      }
    } else if (choice.title == 'settings'.i18n()) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
    } else {
      context.read<UiProvider>().changeTheme();
    }
  }

  Future<void> _handleGoogleSignOut() async {
    await _googleAuthProvider.handleSignOut();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
    );
  }

  Future<void> _handleNaverSignOut() async {
    await _naverAuthProvider.handleSignOut();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
    );
  }

  Future<void> _handleKakaoSignOut() async {
    await _kakaoAuthProvider.handleSignOut();
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [_buildPopupMenu()],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildUserInfoWidget(),
            FutureBuilder<WeatherData>(
              future: futureWeatherData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SkeletonUI();
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (snapshot.hasData) {
                  return WeatherInfo(weatherData: snapshot.data!);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
            FutureBuilder<AirQualityData>(
              future: futureAirQualityData,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (snapshot.hasData) {
                  return AirQualityInfo(airQualityData: snapshot.data!);
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            ),
            const DailyInfoTiles(),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        currentPosition: _currentPosition,
      ),
    );
  }

  Widget _buildPopupMenu() {
    return PopupMenuButton<menu_constants.MenuSetting>(
      onSelected: _onItemMenuPress,
      itemBuilder: (_) {
        return menu_constants.menuSettings.map((choice) {
          return PopupMenuItem<menu_constants.MenuSetting>(
            value: choice,
            child: Row(
              children: [
                Icon(choice.icon, color: ColorConstants.primaryColor),
                SizedBox(width: 10),
                Text(choice.title, style: TextStyle(color: ColorConstants.primaryColor)),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  Widget _buildUserInfoWidget() {
    print('Building user info widget with _userInfo: $_userInfo');
    if (_userInfo != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: _userInfo!.photoUrl.isNotEmpty ? NetworkImage(_userInfo!.photoUrl) : null,
              child: _userInfo!.photoUrl.isNotEmpty ? null : Icon(Icons.account_circle, size: 50, color: ColorConstants.greyColor),
              backgroundColor: ColorConstants.greyColor,
              radius: 20,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _userInfo!.nickname,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _updateWeatherAndAirQuality,
            ),
            IconButton(
              icon: Icon(_isCheckedIn ?? false ? Icons.check_circle : Icons.radio_button_unchecked),
              onPressed: _isCheckedIn ?? false ? null : _checkIn,
            ),
          ],
        ),
      );
    } else {
      return SizedBox();
    }
  }

}
