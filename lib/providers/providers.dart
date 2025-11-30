import 'package:provider/provider.dart';
import 'parcel_provider.dart';

// Exportez tous les providers ici
export 'parcel_provider.dart';

// Liste de tous les providers de l'application
final List providers = [
  // Ajoutez ici tous les providers de l'application
  parcelProvider,
];

// Définition des providers
final parcelProvider =
    ChangeNotifierProvider<ParcelProvider>(create: (_) => ParcelProvider());
