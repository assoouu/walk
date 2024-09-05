import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../model/airQuality_data.dart';
import '../model/weather_data.dart';

class WeatherService {
  final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  Future<WeatherData> fetchWeatherData(double latitude, double longitude) async {
    var url = 'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&lang=kr&units=metric&appid=$apiKey';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return WeatherData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch weather data.');
    }
  }

  Future<AirQualityData> fetchAirQualityData(double latitude, double longitude) async {
    var url = 'http://api.openweathermap.org/data/2.5/air_pollution?lat=$latitude&lon=$longitude&appid=$apiKey';
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return AirQualityData.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to fetch air quality data.');
    }
  }
}
