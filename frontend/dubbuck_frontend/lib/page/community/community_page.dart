import 'package:flutter/material.dart';
import 'package:localization/localization.dart';
import 'picture/photo_page.dart';
import 'ranking/ranking_page.dart';

class CommunityPage extends StatefulWidget {
  @override
  _CommunityPageState createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 0); // "사진" 탭이 기본 탭으로 설정됩니다.
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
        title: Text('community'.i18n()),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'photos'.i18n()),
            Tab(text: 'ranking'.i18n()),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PhotoPage(),
          RankingPage(),
        ],
      ),
    );
  }
}
