import 'package:flutter/material.dart';
import 'package:localization/localization.dart';

class DailyInfoTiles extends StatelessWidget {
  const DailyInfoTiles({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(Icons.directions_walk),
          title: Text('daily-distance'.i18n()),
          trailing: Text('5km'),
        ),
        ListTile(
          leading: Icon(Icons.access_time),
          title: Text('total-time'.i18n()),
          trailing: Text('1h'),
        ),
        ListTile(
          leading: Icon(Icons.map),
          title: Text('total-distance'.i18n()),
          trailing: Text('5km'),
        ),
      ],
    );
  }
}
