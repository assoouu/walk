import 'package:flutter/material.dart';
import 'package:dubbuck_front/model/airQuality_data.dart';
import 'package:localization/localization.dart';

class AirQualityInfo extends StatelessWidget {
  final AirQualityData airQualityData;

  const AirQualityInfo({Key? key, required this.airQualityData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(child: getAirQualityWidget(airQualityData.aqi)), // Center 위젯 추가
    );
  }

  Widget getAirQualityWidget(int condition) {
    String imagePath;
    String text;
    Color textColor;

    switch (condition) {
      case 1:
        imagePath = 'assets/weather/very_good.png';
        text = 'very-good'.i18n();
        textColor = Colors.indigo;
        break;
      case 2:
        imagePath = 'assets/weather/good.png';
        text = 'good'.i18n();
        textColor = Colors.indigo;
        break;
      case 3:
        imagePath = 'assets/weather/moderate.png';
        text = 'moderate'.i18n();
        textColor = Colors.black87;
        break;
      case 4:
        imagePath = 'assets/weather/bad.png';
        text = 'bad'.i18n();
        textColor = Colors.black87;
        break;
      case 5:
        imagePath = 'assets/weather/very_bad.png';
        text = 'very-bad'.i18n();
        textColor = Colors.black87;
        break;
      default:
        imagePath = 'assets/weather/moderate.png';
        text = 'no-information'.i18n();
        textColor = Colors.grey;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center, // 가운데 정렬
      children: [
        Text(
          'fine-dust'.i18n(),
          style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Image.asset(imagePath, width: 24),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
