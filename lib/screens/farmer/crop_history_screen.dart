import 'package:flutter/material.dart';
import '../../models/crop_history.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class CropHistoryScreen extends StatefulWidget {
  const CropHistoryScreen({Key? key}) : super(key: key);

  @override
  State<CropHistoryScreen> createState() => _CropHistoryScreenState();
}

class _CropHistoryScreenState extends State<CropHistoryScreen> {
  final AuthService _authService = AuthService();
  List<CropHistoryRecord> _cropHistory = [];
  bool _isLoadingHistory = false;
  late AppLocalizations _l10n;
  Color _primaryColor = AppTheme.lightTheme.primaryColor;
  bool _isDarkTheme = false;

  @override
  void initState() {
    super.initState();
    _loadCropHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
    _primaryColor = Theme.of(context).primaryColor;
    _isDarkTheme = Theme.of(context).brightness == Brightness.dark;
  }

  Future<void> _loadCropHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final historyData = await _authService.fetchCropHistory();
      print('📊 Données reçues: ${historyData.length} enregistrements');
      
      if (historyData.isNotEmpty) {
        print('📊 Premier enregistrement: ${historyData.first}');
      }
      
      setState(() {
        _cropHistory = historyData
            .map((e) {
              try {
                return CropHistoryRecord.fromJson(e as Map<String, dynamic>);
              } catch (error) {
                print('❌ Erreur parsing enregistrement: $error');
                print('❌ Données: $e');
                return null;
              }
            })
            .whereType<CropHistoryRecord>()
            .toList();
        _isLoadingHistory = false;
      });
      
      print('✅ Historique chargé: ${_cropHistory.length} enregistrements valides');
    } catch (e, stackTrace) {
      print('❌ Erreur chargement historique: $e');
      print('❌ Stack trace: $stackTrace');
      setState(() => _isLoadingHistory = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDarkTheme ? Colors.black : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor:
            _isDarkTheme ? const Color(0xFF1A1A1A) : _primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Historique des Cultures',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoadingHistory
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _cropHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: _isDarkTheme ? Colors.white54 : Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun historique disponible',
                        style: TextStyle(
                          color: _isDarkTheme ? Colors.white70 : Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Les historiques apparaîtront ici après la génération d\'un plan d\'irrigation',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _isDarkTheme ? Colors.white54 : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _loadCropHistory,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Actualiser'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCropHistory,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // En-tête
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isDarkTheme
                              ? const Color(0xFF1A1A1A)
                              : _primaryColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isDarkTheme
                                ? Colors.grey.withOpacity(0.3)
                                : _primaryColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.history,
                              color: _primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "HISTORIQUE DES CULTURES",
                              style: TextStyle(
                                color: _primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Liste des historiques
                      ..._cropHistory.map((record) => _buildHistoryItem(record)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildHistoryItem(CropHistoryRecord record) {
    final cropColors = _getCropBackgroundColor(record.cropType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isDarkTheme ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cropColors['primary']!.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDarkTheme
                ? Colors.black.withOpacity(0.5)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec type de culture et date
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cropColors['primary']!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getCropIcon(record.cropType),
                  color: cropColors['primary'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.cropType,
                      style: TextStyle(
                        color: _isDarkTheme ? Colors.white : Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(record.createdAt),
                      style: TextStyle(
                        color: _isDarkTheme ? Colors.white60 : Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Informations principales
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isDarkTheme 
                  ? Colors.white.withOpacity(0.05)
                  : cropColors['primary']!.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Localisation
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 20,
                      color: cropColors['primary'],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Localisation',
                            style: TextStyle(
                              color: _isDarkTheme ? Colors.white60 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.location,
                            style: TextStyle(
                              color: _isDarkTheme ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Type de sol
                Row(
                  children: [
                    Icon(
                      Icons.grass,
                      size: 20,
                      color: cropColors['primary'],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Type de sol',
                            style: TextStyle(
                              color: _isDarkTheme ? Colors.white60 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getSoilTypeTranslation(record.soilType),
                            style: TextStyle(
                              color: _isDarkTheme ? Colors.white : Colors.black87,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Métrage et Quantité d'eau
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.square_foot,
                            size: 20,
                            color: cropColors['primary'],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Métrage',
                                  style: TextStyle(
                                    color: _isDarkTheme ? Colors.white60 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${record.area.toStringAsFixed(0)} m²',
                                  style: TextStyle(
                                    color: _isDarkTheme ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.water_drop,
                            size: 20,
                            color: cropColors['primary'],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quantité d\'eau',
                                  style: TextStyle(
                                    color: _isDarkTheme ? Colors.white60 : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${record.waterAmount.toStringAsFixed(0)} L',
                                  style: TextStyle(
                                    color: _isDarkTheme ? Colors.white : Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryDetail(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primaryColor),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: _isDarkTheme ? Colors.white60 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: _isDarkTheme ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Map<String, Color> _getCropBackgroundColor(String crop) {
    final lowerCrop = crop.toLowerCase();

    if (lowerCrop.contains("fraise")) {
      return {
        'primary': const Color(0xFFE91E63),
        'secondary': const Color(0xFFF8BBD0),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("tomate")) {
      return {
        'primary': const Color(0xFFF44336),
        'secondary': const Color(0xFFFFCDD2),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("olive")) {
      return {
        'primary': const Color(0xFF4CAF50),
        'secondary': const Color(0xFFC8E6C9),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("blé")) {
      return {
        'primary': const Color(0xFFFFC107),
        'secondary': const Color(0xFFFFECB3),
        'text': Colors.black87,
      };
    } else if (lowerCrop.contains("maïs")) {
      return {
        'primary': const Color(0xFFFF9800),
        'secondary': const Color(0xFFFFE0B2),
        'text': Colors.black87,
      };
    } else if (lowerCrop.contains("rose") || lowerCrop.contains("fleur")) {
      return {
        'primary': const Color(0xFFE91E63),
        'secondary': const Color(0xFFF8BBD0),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("pomme")) {
      return {
        'primary': const Color(0xFF8BC34A),
        'secondary': const Color(0xFFDCEDC8),
        'text': Colors.black87,
      };
    } else if (lowerCrop.contains("raisin")) {
      return {
        'primary': const Color(0xFF9C27B0),
        'secondary': const Color(0xFFE1BEE7),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("carotte")) {
      return {
        'primary': const Color(0xFFFF5722),
        'secondary': const Color(0xFFFFCCBC),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("salade") || lowerCrop.contains("laitue")) {
      return {
        'primary': const Color(0xFF4CAF50),
        'secondary': const Color(0xFFC8E6C9),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("pomme de terre")) {
      return {
        'primary': const Color(0xFF795548),
        'secondary': const Color(0xFFD7CCC8),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("aubergine")) {
      return {
        'primary': const Color(0xFF673AB7),
        'secondary': const Color(0xFFD1C4E9),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("poivron")) {
      return {
        'primary': const Color(0xFFF44336),
        'secondary': const Color(0xFFFFCDD2),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("concombre")) {
      return {
        'primary': const Color(0xFF4CAF50),
        'secondary': const Color(0xFFC8E6C9),
        'text': Colors.white,
      };
    } else if (lowerCrop.contains("courgette")) {
      return {
        'primary': const Color(0xFFFF9800),
        'secondary': const Color(0xFFFFE0B2),
        'text': Colors.black87,
      };
    } else if (lowerCrop.contains("melon")) {
      return {
        'primary': const Color(0xFFFFC107),
        'secondary': const Color(0xFFFFECB3),
        'text': Colors.black87,
      };
    } else if (lowerCrop.contains("pastèque")) {
      return {
        'primary': const Color(0xFFF44336),
        'secondary': const Color(0xFFFFCDD2),
        'text': Colors.white,
      };
    } else {
      return {
        'primary': const Color(0xFF2196F3),
        'secondary': const Color(0xFFBBDEFB),
        'text': Colors.white,
      };
    }
  }

  IconData _getCropIcon(String crop) {
    final lower = crop.toLowerCase();
    if (lower.contains('olive')) {
      return Icons.park;
    } else if (lower.contains('blé')) {
      return Icons.grass;
    } else if (lower.contains('tomate')) {
      return Icons.local_florist;
    } else if (lower.contains('fraise')) {
      return Icons.spa;
    } else if (lower.contains('maïs')) {
      return Icons.eco;
    } else if (lower.contains('rose') || lower.contains('fleur')) {
      return Icons.local_florist;
    } else if (lower.contains('pomme')) {
      return Icons.apple;
    } else if (lower.contains('raisin')) {
      return Icons.wine_bar;
    } else if (lower.contains('carotte')) {
      return Icons.eco;
    } else if (lower.contains('salade') || lower.contains('laitue')) {
      return Icons.eco;
    } else if (lower.contains('pomme de terre')) {
      return Icons.agriculture;
    } else if (lower.contains('aubergine')) {
      return Icons.eco;
    } else if (lower.contains('poivron')) {
      return Icons.local_florist;
    } else if (lower.contains('concombre')) {
      return Icons.eco;
    } else if (lower.contains('courgette')) {
      return Icons.eco;
    } else if (lower.contains('melon')) {
      return Icons.water_drop;
    } else if (lower.contains('pastèque')) {
      return Icons.water_drop;
    }
    return Icons.agriculture;
  }

  String _getSoilTypeTranslation(String soilType) {
    switch (soilType.toLowerCase()) {
      case 'sableux':
        return _l10n.sandySoil;
      case 'argileux':
        return _l10n.claySoil;
      case 'limoneux':
        return _l10n.loamySoil;
      default:
        return soilType;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return "Aujourd'hui";
    } else if (diff.inDays == 1) {
      return "Hier";
    } else if (diff.inDays < 7) {
      return "Il y a ${diff.inDays} jours";
    } else {
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
    }
  }
}

