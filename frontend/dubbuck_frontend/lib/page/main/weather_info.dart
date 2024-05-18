import 'package:dubbuck_front/model/weather_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';

class WeatherInfo extends StatelessWidget {
  final WeatherData weatherData;

  const WeatherInfo({Key? key, required this.weatherData}) : super(key: key);

  String _getHumidityImage(int humidity) {
    if (humidity >= 70) {
      return 'assets/weather/humidity_high.png';
    } else if (humidity >= 30) {
      return 'assets/weather/humidity_mid.png';
    } else {
      return 'assets/weather/humidity_low.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Image.network(weatherData.getIconUrl(), width: 48),
              SizedBox(width: 8),
              Text('${weatherData.temperature}°C', style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
          Row(
            children: [
              Text('${'feels-like'.i18n()} ${weatherData.feelsLike}°C', style: TextStyle(color: Colors.deepOrangeAccent)),
              SizedBox(width: 8),
              Icon(Icons.wind_power_outlined, color: Colors.blueGrey, size: 24),
              SizedBox(width: 8),
              Text('${'wind-speed'.i18n()} ${weatherData.windSpeed}m/s', style: TextStyle(color: Colors.blueGrey)),
            ],
          ),
          Row(
            children: [
              Image.asset(
                _getHumidityImage(weatherData.humidity), // 습도에 따라 이미지 파일 가져오기
                width: 24,
              ),
              SizedBox(width: 8),
              Text('${'humidity'.i18n()}  ${weatherData.humidity}%', style: TextStyle(color: Colors.blueAccent)),
              SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }
}
