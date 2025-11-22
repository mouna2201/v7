import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../widgets/custom_button.dart';
import 'irrigation_plan_screen.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

class FarmerFormScreen extends StatefulWidget {
  final String farmerName;

  const FarmerFormScreen({super.key, required this.farmerName});

  @override
  State<FarmerFormScreen> createState() => _FarmerFormScreenState();
}

class _FarmerFormScreenState extends State<FarmerFormScreen> {
  String soil = "sableux"; // utiliser la clé en minuscules pour la traduction
  final TextEditingController location = TextEditingController();
  final TextEditingController crop = TextEditingController();
  final TextEditingController hectares = TextEditingController();
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.farmerTheme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _l10n.parcelDetails,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon:
                  Icon(Icons.palette, color: AppTheme.farmerTheme.primaryColor),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Changement de thème bientôt disponible"),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE8F5E9),
                Color(0xFFF1FAF2),
              ],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.map_outlined,
                                  color: Color(0xFF1B5E20)),
                              const SizedBox(width: 8),
                              Text(
                                _l10n.locationField,
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: location,
                            label: _l10n.locationHint,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.grass, color: Color(0xFF1B5E20)),
                              const SizedBox(width: 8),
                              Text(
                                _l10n.soilType,
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: soil,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Color(0xFF1B5E20),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            items: [
                              "sableux",
                              "argileux",
                              "calcaire",
                              "limoneux",
                            ]
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) => setState(() => soil = v ?? soil),
                            decoration: _inputDecoration(),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.eco_outlined,
                                  color: Color(0xFF1B5E20)),
                              const SizedBox(width: 8),
                              Text(
                                _l10n.cropTypes,
                                style: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: crop,
                            label: _l10n.cropHint,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(Icons.square_foot,
                                  color: Color(0xFF1B5E20)),
                              const SizedBox(width: 8),
                              const Text(
                                '📏 Superficie (m²)',
                                style: TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: hectares,
                            label: 'Ex: 500 (m²)',
                            type: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: _l10n.generateAIPlan,
                              onTap: () async {
                                if (location.text.isEmpty ||
                                    crop.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(_l10n.fillAllFields),
                                    ),
                                  );
                                  return;
                                }

                                final cropList = crop.text
                                    .split(',')
                                    .map((c) => c.trim())
                                    .where((c) => c.isNotEmpty)
                                    .toList();

                                // Sauvegarder le plan d'irrigation pour ce fermier
                                final prefs = await SharedPreferences.getInstance();
                                final normalizedName = widget.farmerName
                                    .toLowerCase()
                                    .replaceAll(' ', '_');
                                final planKey = 'farmer_plan_'
                                    '$normalizedName';

                                await prefs.setString(
                                  planKey,
                                  jsonEncode({
                                    'location': location.text,
                                    'soilType': soil,
                                    'crops': cropList,
                                  }),
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => IrrigationPlanScreen(
                                      location: location.text,
                                      soilType: soil,
                                      cropTypes: cropList,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🌸 Label stylé
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF1B5E20), // Vert très foncé
        fontWeight: FontWeight.w600,
        fontSize: 12, // Encore plus réduit
        letterSpacing: 0.3,
      ),
    );
  }

  // 🧩 Champ de texte avec style unifié
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? type,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(
          color: Color(0xFF1B5E20),
          fontSize: 12,
          fontWeight: FontWeight.w500), // Encore plus réduit
      decoration: _inputDecoration(hint: label),
    );
  }

  // 🎨 Style global des champs
  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:
          const TextStyle(color: Color(0xFF66BB6A), fontSize: 12), // Réduit
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 8, vertical: 8), // Encore plus réduit
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6), // Encore plus réduit
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6), // Encore plus réduit
        borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1),
      ),
    );
  }
}
