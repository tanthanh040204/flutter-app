import 'package:flutter/material.dart';

enum AppLanguage { vi, en }

class AppLanguageProvider extends ChangeNotifier {
  AppLanguage _language = AppLanguage.vi;

  AppLanguage get language => _language;

  bool get isVietnamese => _language == AppLanguage.vi;

  Locale get locale => Locale(_language == AppLanguage.vi ? 'vi' : 'en');

  String get languageLabel => _language == AppLanguage.vi ? 'Tiếng Việt' : 'English';

  void setLanguage(AppLanguage language) {
    if (_language == language) return;
    _language = language;
    notifyListeners();
  }
}
