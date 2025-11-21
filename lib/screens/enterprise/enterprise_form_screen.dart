import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../theme/app_theme.dart';
import '../farmer/irrigation_plan_screen.dart';

class EnterpriseFormScreen extends StatefulWidget {
  const EnterpriseFormScreen({super.key});

  @override
  State<EnterpriseFormScreen> createState() => _EnterpriseFormScreenState();
}

class _EnterpriseFormScreenState extends State<EnterpriseFormScreen> {
  String soil = "sableux";
  final TextEditingController location = TextEditingController();
  final TextEditingController crop = TextEditingController();
  final TextEditingController hectares = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.enterpriseTheme;

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Détails de la parcelle",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.palette, color: theme.colorScheme.primary),
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel("Localisation"),
              const SizedBox(height: 2),
              _buildTextField(
                controller: location,
                label: "Ex: Bizerte, Tunisie",
              ),
              const SizedBox(height: 8),
              _buildLabel("Type de sol"),
              const SizedBox(height: 2),
              DropdownButtonFormField<String>(
                value: soil,
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Color(0xFF0D47A1),
                  fontSize: 16,
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
                        child: Text(
                          e,
                          style: const TextStyle(
                            color: Color(0xFF0D47A1),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => soil = v ?? soil),
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 8),
              _buildLabel("Types de cultures"),
              const SizedBox(height: 2),
              _buildTextField(
                controller: crop,
                label: "Ex: Tomate, Blé, Olive...",
              ),
              const SizedBox(height: 8),
              _buildLabel("Superficie (hectares)"),
              const SizedBox(height: 2),
              _buildTextField(
                controller: hectares,
                label: "Ex: 5",
                type: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: 220,
                  child: CustomButton(
                    text: "Générer le plan IA",
                    onTap: () {
                      if (location.text.isEmpty || crop.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Veuillez remplir tous les champs"),
                          ),
                        );
                        return;
                      }

                      final cropList = crop.text
                          .split(',')
                          .map((c) => c.trim())
                          .where((c) => c.isNotEmpty)
                          .toList();

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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF0D47A1),
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? type,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(
        color: Color(0xFF0D47A1),
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: _inputDecoration(hint: label),
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF64B5F6),
        fontSize: 12,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: Color(0xFF1976D2), width: 1),
      ),
    );
  }
}
