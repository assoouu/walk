import 'package:flutter/material.dart';
import 'package:localization/localization.dart';

class MenuSetting {
  final String title;
  final IconData icon;

  MenuSetting({required this.title, required this.icon});
}

final List<MenuSetting> menuSettings = [
  MenuSetting(title: 'settings'.i18n(), icon: Icons.settings),
  MenuSetting(title: 'log-out'.i18n(), icon: Icons.exit_to_app),
  MenuSetting(title: 'dark-theme'.i18n(), icon: Icons.dark_mode),
];
