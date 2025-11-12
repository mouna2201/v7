import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import 'irrigation_plan_screen.dart';
import '../../theme/app_theme.dart';

class FarmerFormScreen extends StatefulWidget {
  const FarmerFormScreen({super.key});

  @override
  State<FarmerFormScreen> createState() => _FarmerFormScreenState();
}

class _FarmerFormScreenState extends State<FarmerFormScreen> {
  String soil = "Sableux";
  final TextEditingController location = TextEditingController();
  final TextEditingController crop = TextEditingController();
  final TextEditingController hectares = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.farmerTheme,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Détails de la parcelle",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8), // Encore plus réduit
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildLabel("📍 Localisation"),
            const SizedBox(height: 2), // Encore plus réduit
            _buildTextField(
              controller: location,
              label: "Ex: Bizerte, Tunisie",
            ),
            const SizedBox(height: 8), // Encore plus réduit

            _buildLabel("🌾 Type de sol"),
            const SizedBox(height: 2), // Encore plus réduit
            DropdownButtonFormField(
              value: soil,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 16, fontWeight: FontWeight.w500),
              items: ["Sableux", "Argileux", "Calcaire", "Limoneux"]
                  .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e,
                            style: const TextStyle(
                                color: Color(0xFF1B5E20), fontSize: 16, fontWeight: FontWeight.w500)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => soil = v!),
              decoration: _inputDecoration(),
            ),
            const SizedBox(height: 8), // Encore plus réduit

            _buildLabel("🌱 Types de cultures"),
            const SizedBox(height: 2), // Encore plus réduit
            _buildTextField(
              controller: crop,
              label: "Ex: tomate, maïs, olive...",
            ),
            const SizedBox(height: 8), // Encore plus réduit

            _buildLabel("📏 Superficie (hectares)"),
            const SizedBox(height: 2), // Encore plus réduit
            _buildTextField(
              controller: hectares,
              label: "Ex: 2.5",
              type: TextInputType.number,
            ),
            const SizedBox(height: 12), // Encore plus réduit

            CustomButton(
              text: "Générer le plan IA 🌱",
              onTap: () {
                if (location.text.isEmpty || crop.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Veuillez remplir tous les champs."),
                      backgroundColor: Colors.redAccent,
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
          ],
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
      style: const TextStyle(color: Color(0xFF1B5E20), fontSize: 12, fontWeight: FontWeight.w500), // Encore plus réduit
      decoration: _inputDecoration(hint: label),
    );
  }

  // 🎨 Style global des champs
  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF66BB6A), fontSize: 12), // Réduit
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Encore plus réduit
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
