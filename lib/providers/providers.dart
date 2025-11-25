import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'parcel_provider.dart';

// Exportez tous les providers ici
export 'parcel_provider.dart';

// Liste de tous les providers de l'application
final List<Override> providers = [
  // Ajoutez ici tous les providers de l'application
  parcelProvider,
];

// Définition des providers
final parcelProvider = ChangeNotifierProvider<ParcelProvider>((ref) {
  return ParcelProvider();
});
