import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../theme/app_theme.dart';
import '../farmer/irrigation_plan_screen.dart';
import '../enterprise/enterprise_role_screen.dart';
import '../../services/auth_service.dart';

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
  final AuthService _authService = AuthService();

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
              icon: Icon(Icons.logout, color: theme.colorScheme.primary),
              tooltip: 'Se déconnecter',
              onPressed: () async {
                await _authService.logout();
                if (!mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const EnterpriseRoleScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE3F2FD),
                Color(0xFFEEF7FF),
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
                            children: const [
                              Icon(Icons.map_outlined,
                                  color: Color(0xFF0D47A1)),
                              SizedBox(width: 8),
                              Text(
                                "Localisation",
                                style: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: location,
                            label: "Ex: Bizerte, Tunisie",
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: const [
                              Icon(Icons.grass, color: Color(0xFF0D47A1)),
                              SizedBox(width: 8),
                              Text(
                                "Type de sol",
                                style: TextStyle(
                                  color: Color(0xFF0D47A1),
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
                              color: Color(0xFF0D47A1),
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
                            children: const [
                              Icon(Icons.eco_outlined,
                                  color: Color(0xFF0D47A1)),
                              SizedBox(width: 8),
                              Text(
                                "Types de cultures",
                                style: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: crop,
                            label: "Ex: Tomate, Blé, Olive...",
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: const [
                              Icon(Icons.square_foot, color: Color(0xFF0D47A1)),
                              SizedBox(width: 8),
                              Text(
                                "Superficie (hectares)",
                                style: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _buildTextField(
                            controller: hectares,
                            label: "Ex: 5",
                            type: TextInputType.number,
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: "Générer le plan IA",
                              onTap: () {
                                if (location.text.isEmpty ||
                                    crop.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          "Veuillez remplir tous les champs"),
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
