import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'package:geolocator/geolocator.dart';
import 'calendar_page.dart';
import 'log_page.dart';

class DiaryHomePage extends StatefulWidget {
  final Position currentPosition;

  DiaryHomePage({required this.currentPosition});

  @override
  _DiaryHomePageState createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('record'.i18n()),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'diary'.i18n()),
            Tab(text: 'calendar'.i18n()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          LogPage(imageUrls: [], initialPage: 0),
          CalendarPage(currentPosition: widget.currentPosition),
        ],
      ),
    );
  }
}
