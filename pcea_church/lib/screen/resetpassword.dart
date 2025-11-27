import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/screen/login.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String code;
  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  bool isLoading = false;
  bool showPassword = false;
  bool showConfirmPassword = false;

  void resetPassword() async {
    // Get passwords and validate
    String password = passwordController.text.trim();
    String confirmPassword = confirmController.text.trim();

    if (password.length < 6) {
      showMessage('Password must be at least 6 characters');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Passwords do not match');
      return;
    }

    // Show loading
    setState(() => isLoading = true);

    try {
      // Call API to reset password
      var response = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/reset-password'),
        data: {
          'email': widget.email,
          'code': widget.code,
          'password': password,
          'password_confirmation': confirmPassword,
        },
      );

      var result = jsonDecode(response.body);

      if (result['status'] == 200) {
        API.showSnack(context, 'Password reset successfully!', success: true);
        // Go back to login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      } else {
        API.showSnack(context, result['message'], success: false);
      }
    } catch (e) {
      API.showSnack(context, 'Something went wrong', success: false);
    }

    setState(() => isLoading = false);
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildResetCard() {
    const primaryColor = Color(0xFF0A1F44);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: ClipOval(
                child: Image.asset("assets/icon.png", fit: BoxFit.contain),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Reset Password",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: passwordController,
              obscureText: !showPassword,
              decoration: InputDecoration(
                hintText: 'Enter new password',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => showPassword = !showPassword),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: confirmController,
              obscureText: !showConfirmPassword,
              decoration: InputDecoration(
                hintText: 'Confirm new password',
                border: InputBorder.none,
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(
                    showConfirmPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(
                    () => showConfirmPassword = !showConfirmPassword,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: isLoading ? null : resetPassword,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Reset Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildResetCard(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return DesktopScaffoldFrame(
      backgroundColor: const Color(0xFFE8F4FD),
      title: '',
      primaryColor: const Color(0xFF35C2C1),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: _buildResetCard(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }
}
