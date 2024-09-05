import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:localization/localization.dart';

import '../community/community_page.dart';
import '../chat/chat_home_page.dart';
import '../dubbuck/dubbuck_page.dart';
import '../dubbuckDiary/diary_home_page.dart';
import '../seongkeum/seongkeum_page.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final void Function(int) onItemTapped;
  final Position? currentPosition;

  const CustomBottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    required this.currentPosition,
  }) : super(key: key);

  Widget _navBarItem(IconData icon, String label, int index, BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (index) {
          case 0:
            Navigator.push(context, MaterialPageRoute(builder: (context) => DubbuckPage()));
            break;
          case 1:
            if (currentPosition != null) {
              Navigator.push(context, MaterialPageRoute(
                builder: (context) => SeongkeumPage(
                  latitude: currentPosition!.latitude,
                  longitude: currentPosition!.longitude,
                ),
              ));
            }
            break;
          case 2:
            if (currentPosition != null) {
              Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryHomePage(currentPosition: currentPosition!)));
            }
            break;
          case 3:
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatHomePage()));
            break;
          case 4:
            Navigator.push(context, MaterialPageRoute(builder: (context) => CommunityPage()));
            break;
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _navBarItem(Icons.directions_run, 'stroll'.i18n(), 0, context),
          _navBarItem(Icons.hiking, 'stride'.i18n(), 1, context),
          _navBarItem(Icons.photo_library, 'record'.i18n(), 2, context),
          _navBarItem(Icons.chat, 'chat'.i18n(), 3, context),
          _navBarItem(Icons.group, 'community'.i18n(), 4, context),
        ],
      ),
    );
  }
}
