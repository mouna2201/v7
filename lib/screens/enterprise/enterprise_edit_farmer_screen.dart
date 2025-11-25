import 'package:flutter/material.dart';
import '../../widgets/custom_button.dart';
import '../../services/auth_service.dart';
import '../../models/user.dart';

class EnterpriseEditFarmerScreen extends StatefulWidget {
  final User farmer;

  const EnterpriseEditFarmerScreen({super.key, required this.farmer});

  @override
  State<EnterpriseEditFarmerScreen> createState() => _EnterpriseEditFarmerScreenState();
}

class _EnterpriseEditFarmerScreenState extends State<EnterpriseEditFarmerScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.farmer.name;
    _emailController.text = widget.farmer.email;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final updated = await _authService.updateUser(
      id: widget.farmer.id,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.isEmpty
          ? null
          : _passwordController.text,
    );

    setState(() => _loading = false);

    if (updated == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de la mise à jour du fermier'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le fermier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nom'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nom obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email obligatoire';
                  }
                  if (!value.contains('@')) {
                    return 'Email invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Nouveau mot de passe (optionnel)',
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: _loading ? 'En cours...' : 'Enregistrer',
                onTap: () {
                  if (_loading) return;
                  _save();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
