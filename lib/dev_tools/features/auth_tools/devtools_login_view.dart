import 'package:flutter/material.dart';
import '../../../core/constants/dimensions.dart';
import 'devtools_auth_controller.dart';

class DevToolsLoginView extends StatefulWidget {
  const DevToolsLoginView({super.key});

  @override
  State<DevToolsLoginView> createState() => _DevToolsLoginViewState();
}

class _DevToolsLoginViewState extends State<DevToolsLoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _obscurePassword = ValueNotifier<bool>(true);
  final _errorMessage = ValueNotifier<String?>(null);
  final authController = DevToolsAuthController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
    _errorMessage.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    _errorMessage.value = null;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _errorMessage.value = "Please enter both email and password";
      return;
    }

    try {
      await authController.loginWithCredentials(email, password);
    } catch (e) {
      _errorMessage.value = e.toString().contains("Exception:")
          ? e.toString().split("Exception:").last.trim()
          : "Invalid email or password";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF131313),
        borderRadius: BorderRadius.vertical(top: Radius.circular(Dimen.r20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          Dimen.w24,
          0,
          Dimen.w24,
          MediaQuery.of(context).viewInsets.bottom + Dimen.h20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: Dimen.h12),
            _buildHandle(),
            SizedBox(height: Dimen.h30),
            Icon(
              Icons.lock_person_outlined,
              size: Dimen.h50,
              color: Colors.blueAccent,
            ),
            SizedBox(height: Dimen.h16),
            Text(
              "DevTools Access",
              style: TextStyle(
                color: Colors.white,
                fontSize: Dimen.s22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: Dimen.h8),
            Text(
              "Enter credentials to unlock tools",
              style: TextStyle(color: Colors.white54, fontSize: Dimen.s14),
            ),
            SizedBox(height: Dimen.h30),

            // Email Field
            _buildTextField(
              controller: _emailController,
              label: "Email Address",
              hint: "admin@devtools.app",
              icon: Icons.alternate_email_rounded,
            ),
            SizedBox(height: Dimen.h16),

            // Password Field
            ValueListenableBuilder<bool>(
              valueListenable: _obscurePassword,
              builder: (context, obscure, _) {
                return _buildTextField(
                  controller: _passwordController,
                  label: "Password",
                  hint: "••••••••",
                  icon: Icons.key_rounded,
                  isPassword: true,
                  obscureText: obscure,
                  onToggleVisibility: () => _obscurePassword.value = !obscure,
                );
              },
            ),

            // Error Message
            ValueListenableBuilder<String?>(
              valueListenable: _errorMessage,
              builder: (context, error, _) {
                if (error == null) return const SizedBox.shrink();
                return Padding(
                  padding: EdgeInsets.only(top: Dimen.h12),
                  child: Text(
                    error,
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: Dimen.s12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: Dimen.h30),

            // Login Button
            ValueListenableBuilder<bool>(
              valueListenable: authController.isAuthenticating,
              builder: (context, isSyncing, _) {
                return SizedBox(
                  width: double.infinity,
                  height: Dimen.h50,
                  child: ElevatedButton(
                    onPressed: isSyncing ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Dimen.r12),
                      ),
                      elevation: 0,
                    ),
                    child: isSyncing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeAlign: BorderSide.strokeAlignInside,
                            ),
                          )
                        : Text(
                            "Authorize Access",
                            style: TextStyle(
                              fontSize: Dimen.s16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),

            SizedBox(height: Dimen.h40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white38,
            fontSize: Dimen.s11,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: Dimen.h8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: Colors.white, fontSize: Dimen.s15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white12),
            prefixIcon: Icon(
              icon,
              color: Colors.blueAccent.withValues(alpha: 0.5),
              size: Dimen.h20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.white24,
                      size: Dimen.h18,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(Dimen.r12),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(vertical: Dimen.h16),
          ),
        ),
      ],
    );
  }

  Widget _buildHandle() {
    return Container(
      width: Dimen.w40,
      height: Dimen.h4,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(Dimen.r2),
      ),
    );
  }
}
