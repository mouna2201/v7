import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Provider pour gérer la langue de l'application
final languageProvider = StateProvider<Locale>((ref) {
  return const Locale('fr', ''); // Français par défaut
});

/// Helper pour changer la langue
void changeLanguage(WidgetRef ref, String langCode) {
  ref.read(languageProvider.notifier).state = Locale(langCode, '');
}
