import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dubbuck_front/model/airQuality_data.dart';
import 'package:dubbuck_front/model/weather_data.dart';
import 'package:dubbuck_front/page/settings_page.dart';
import 'package:dubbuck_front/page/main/weather_info.dart';
import 'package:dubbuck_front/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:localization/localization.dart';
import 'package:provider/provider.dart';
import 'package:skeletons/skeletons.dart';

import '../../constant/color_constants.dart';
import '../../model/menu_setting.dart';
import '../../model/user_information.dart';
import '../../providers/google_auth_provider.dart';
import '../../providers/kakao_auth_provider.dart';
import '../../providers/naver_auth_provider.dart';
import '../login/login_page.dart';
import 'airQuality_info.dart';
import 'custom_bottom_nav_bar.dart';
import 'daily_info_tiles.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  Future<WeatherData>? futureWeatherData;
  Future<AirQualityData>? futureAirQualityData;

  UserInformation? _userInfo;
  late final _googleAuthProvider = context.read<AuthProviderGoogle>();
  late final _naverAuthProvider = Provider.of<AuthProviderNaver>( context, listen: false);
  late final _kakaoAuthProvider = context.read<AuthProviderKakao>();


  final _menus = <MenuSetting>[
    MenuSetting(title: 'settings'.i18n(), icon: Icons.settings),
    MenuSetting(title: 'log-out'.i18n(), icon: Icons.exit_to_app),
    MenuSetting(title: 'dark-theme'.i18n(), icon: Icons.dark_mode),
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocationAndData();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfoById(String userId) async {
    DocumentSnapshot userInfoSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    setState(() {
      _userInfo = UserInformation.fromDocument(userInfoSnapshot);
    });
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${'failed-to-fetch-user-information'.i18n()}: $e'),
      ));
    }
  }

  Future<Position> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      throw Exception('${'location-service-disabled'.i18n()}.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('${'location-permission-denied'.i18n()}.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('${'location-permission-denied-forever'.i18n()}.');
    }

    return await Geolocator.getCurrentPosition();
  }

  void _fetchLocationAndData() async {
    try {
      Position position = await _getCurrentLocation();
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
      var apiKey = dotenv.env['WEATHER_API_KEY'];
      var url =
          'https://api.openweathermap.org/data/2.5/weather?lat=${position
          .latitude}&lon=${position
          .longitude}&lang=kr&units=metric&appid=$apiKey';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        WeatherData weatherData = WeatherData.fromJson(
            json.decode(response.body));
        setState(() {
          futureWeatherData = Future.value(weatherData);
        });
      } else {
        throw Exception('${'failed-to-fetch-weather-data'.i18n()}.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${'failed-to-fetch-weather-data'.i18n()}: $e'),
      ));
    }
  }

  void _fetchAirQualityData(Position position) async {
    try {
      var apiKey = dotenv.env['WEATHER_API_KEY'];
      var airQualityUrl =
          'http://api.openweathermap.org/data/2.5/air_pollution?lat=${position
          .latitude}&lon=${position.longitude}&appid=$apiKey';
      var response = await http.get(Uri.parse(airQualityUrl));
      if (response.statusCode == 200) {
        AirQualityData airQualityData = AirQualityData.fromJson(
            json.decode(response.body));
        setState(() {
          futureAirQualityData = Future.value(airQualityData);
        });
      } else {
        throw Exception('${'failed-to-fetch-air-quality-data'.i18n()}.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${'failed-to-fetch-air-quality-data'.i18n()}: $e'),
      ));
    }
  }

  Widget _buildSkeletonUI() {
    return SkeletonListView(
      itemCount: 3,
      itemBuilder: (context, index) =>
          Padding(
            padding: EdgeInsets.all(8.0),
            child: SkeletonItem(
              child: Row(
                children: <Widget>[
                  SkeletonAvatar(
                      style: SkeletonAvatarStyle(width: 60, height: 60)),
                  SizedBox(width: 10),
                  Expanded(
                    child: SkeletonParagraph(
                      style: SkeletonParagraphStyle(
                          lines: 3,
                          spacing: 6,
                          lineStyle: SkeletonLineStyle(randomLength: true)),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onItemMenuPress(MenuSetting choice) {
    if (choice.title == 'log-out'.i18n()) {
      if (_googleAuthProvider.status == GoogleStatus.authenticated) {
        _handleGoogleSignOut();
      } else if (_naverAuthProvider.status == NaverStatus.authenticated) {
        _handleNaverSignOut();
      } else if (_kakaoAuthProvider.status == KakaoStatus.authenticated) {
        _handleKakaoSignOut();
      }
    }else if (choice.title == 'settings'.i18n()) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => SettingsPage()));
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
                  return _buildSkeletonUI();
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
      ),
    );
  }


  Widget _buildPopupMenu() {
    return PopupMenuButton<MenuSetting>(
      onSelected: _onItemMenuPress,
      itemBuilder: (_) {
        return _menus.map(
              (choice) {
            return PopupMenuItem<MenuSetting>(
              value: choice,
              child: Row(
                children: [
                  Icon(
                    choice.icon,
                    color: ColorConstants.primaryColor,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    choice.title,
                    style: TextStyle(color: ColorConstants.primaryColor),
                  ),
                ],
              ),
            );
          },
        ).toList();
      },
    );
  }

  Widget _buildUserInfoWidget() {
    if (_userInfo != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: _userInfo!.photoUrl.isNotEmpty
                  ? NetworkImage(_userInfo!.photoUrl)
                  : null,
              child: _userInfo!.photoUrl.isNotEmpty
                  ? null
                  : Icon(
                Icons.account_circle,
                size: 50,
                color: ColorConstants.greyColor,
              ),
              backgroundColor: ColorConstants.greyColor,
              radius: 20,
            ),
            SizedBox(width: 10),
            Text(
              _userInfo!.nickname,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return SizedBox();
    }
  }
}
