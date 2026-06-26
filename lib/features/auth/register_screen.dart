import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/auth_service.dart';
import '../../core/widgets/app_widgets.dart';
import '../../models/app_user.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  UserRole _selectedRole = UserRole.elderly; // sensible default
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Please fill in all the fields.');
      return;
    }
    if (password.length < 6) {
      _showMessage('Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      _showMessage('The two passwords do not match.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().register(
            name: name,
            email: email,
            password: password,
            role: _selectedRole,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showMessage(friendlyAuthError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontSize: 16))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account', style: TextStyle(fontSize: 22))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text("Let's set up your account",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // ----- Role selection -----
              const Text('I am a:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _roleCard(
                      role: UserRole.elderly,
                      title: 'Elderly User',
                      icon: Icons.elderly,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _roleCard(
                      role: UserRole.caregiver,
                      title: 'Caregiver',
                      icon: Icons.favorite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              AppTextField(controller: _nameController, label: 'Full Name', icon: Icons.person),
              const SizedBox(height: 20),
              AppTextField(
                controller: _emailController,
                label: 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              AppTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: true),
              const SizedBox(height: 20),
              AppTextField(
                  controller: _confirmController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  obscureText: true),
              const SizedBox(height: 28),
              AppButton(
                label: 'Create Account',
                icon: Icons.person_add,
                isLoading: _isLoading,
                onPressed: _register,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// A large, tappable card for choosing a role. Highlights when selected.
  Widget _roleCard({
    required UserRole role,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == role;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => setState(() => _selectedRole = role),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primaryContainer : Colors.transparent,
          border: Border.all(
            color: isSelected ? scheme.primary : Colors.grey,
            width: isSelected ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: isSelected ? scheme.primary : Colors.grey[700]),
            const SizedBox(height: 8),
            Text(title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                )),
          ],
        ),
      ),
    );
  }
}
