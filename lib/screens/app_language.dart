import 'package:flutter/material.dart';

class AppLanguage extends ChangeNotifier {
  String _currentLang = 'fr'; // langue par défaut

  String get currentLang => _currentLang;

  // changer de langue automatiquement
  void changeLanguage() {
    if (_currentLang == 'fr') {
      _currentLang = 'en';
    } else if (_currentLang == 'en') {
      _currentLang = 'ar';
    } else {
      _currentLang = 'fr';
    }
    notifyListeners(); // ⚡ avertit toute l'app que la langue a changé
  }

  // changer directement vers une langue spécifique
  void changeTo(String lang) {
    _currentLang = lang;
    notifyListeners();
  }
}
