import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'calendar_page.dart';
import 'log_page.dart';

class DiraryHomePage extends StatefulWidget {
  @override
  _DiraryHomePageState createState() => _DiraryHomePageState();
}

class _DiraryHomePageState extends State<DiraryHomePage> with SingleTickerProviderStateMixin {
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
          LogPage(imageUrls: [], initialPage: 0), // '기록' 탭에는 LogPage를 표시하고 imageUrls를 빈 배열로 전달합니다.
          CalendarPage(),
        ],
      ),
    );
  }
}
