import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/resetpassword.dart';

class VerifyResetCodeScreen extends StatefulWidget {
  final String identifier; // Changed from email to identifier
  final String? channel; // 'email' or 'sms'
  const VerifyResetCodeScreen({
    super.key,
    required this.identifier,
    this.channel,
  });

  @override
  State<VerifyResetCodeScreen> createState() => _VerifyResetCodeScreenState();
}

class _VerifyResetCodeScreenState extends State<VerifyResetCodeScreen> {
  final codeController = TextEditingController();
  bool isLoading = false;

  void verifyCode() async {
    // Get code and check if valid
    String code = codeController.text.trim();
    if (code.length != 6) {
      showMessage('Please enter the 6-digit code');
      return;
    }

    // Show loading
    setState(() => isLoading = true);

    try {
      print('Verifying code for identifier: ${widget.identifier}');
      print('Code: $code');

      // Call API to verify code
      var response = await API().postRequest(
        url: Uri.parse('${Config.baseUrl}/verify-reset-code'),
        data: {'identifier': widget.identifier, 'code': code},
      );

      print('Verification response status: ${response.statusCode}');
      print('Verification response body: ${response.body}');

      var result = jsonDecode(response.body);

      if (result['status'] == 200) {
        API.showSnack(context, 'Code verified successfully', success: true);
        // Use the email from the API response for the next step
        String email = result['email'] ?? widget.identifier;
        // Go to reset password screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: email, code: code),
          ),
        );
      } else {
        API.showSnack(context, result['message'], success: false);
      }
    } catch (e) {
      print('Error verifying code: $e');
      API.showSnack(context, 'Something went wrong: $e', success: false);
    }

    setState(() => isLoading = false);
  }

  void showMessage(String message) {}

  Widget _buildVerifyCard() {
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
            'Verify Code',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              widget.channel == "sms"
                  ? "Reset code has been sent via SMS"
                  : "Reset code has been sent to your email",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
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
              controller: codeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 20),
              decoration: const InputDecoration(
                hintText: 'Enter 6-digit code to verify',
                border: InputBorder.none,
                counterText: '',
                prefixIcon: Icon(
                  Icons.verified_user_outlined,
                  color: Colors.black,
                ),
              ),
              maxLength: 6,
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
              onPressed: isLoading ? null : verifyCode,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Verify Code',
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
          child: _buildVerifyCard(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return DesktopScaffoldFrame(
      backgroundColor: const Color(0xFFE8F4FD),
      title: '',
      primaryColor: Colors.black87,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: _buildVerifyCard(),
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
