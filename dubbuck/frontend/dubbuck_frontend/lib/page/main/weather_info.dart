import 'package:cached_network_image/cached_network_image.dart';
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          weatherData.getIconUrl().startsWith('http')
              ? CachedNetworkImage(
            imageUrl: weatherData.getIconUrl(),
            width: 80, // 이미지 크기 증가
            placeholder: (context, url) => CircularProgressIndicator(),
            errorWidget: (context, url, error) {
              debugPrint('Error loading image: $error');
              return Icon(Icons.error);
            },
          )
              : Image.asset(
            weatherData.getIconUrl(),
            width: 80, // 이미지 크기 증가
          ),
          SizedBox(height: 4),
          Text(
            '${weatherData.temperature}°C',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center, // 가운데 정렬
          ),
          SizedBox(height: 4),
          Text(
            '${'feels-like'.i18n()} ${weatherData.feelsLike}°C',
            style: TextStyle(color: Colors.deepOrangeAccent),
            textAlign: TextAlign.center, // 가운데 정렬
          ),
          SizedBox(height: 16), // 여백 추가
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
            children: [
              Icon(
                Icons.wind_power_outlined,
                color: Colors.blueGrey,
                size: 24,
              ),
              SizedBox(width: 8),
              Text(
                '${'wind-speed'.i18n()} ${weatherData.windSpeed}m/s',
                style: TextStyle(color: Colors.blueGrey),
              ),
              SizedBox(width: 8),
              Image.asset(
                _getHumidityImage(weatherData.humidity),
                width: 24,
              ),
              SizedBox(width: 8),
              Text(
                '${'humidity'.i18n()} ${weatherData.humidity}%',
                style: TextStyle(color: Colors.blueAccent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
