import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/dashboard.dart';
import 'package:pcea_church/screen/forgotpassword.dart';
import 'package:pcea_church/screen/member_onboard.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController ekanisaController = TextEditingController();

  String _loginMode = 'Use your email address';
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _isCheckingAutoLogin = true;

  final primaryColor = const Color(0xFF0A1F44);

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  // ---- Auto Login Check ----
  Future<void> _checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        // Validate token by making an authenticated request
        try {
          final result = await API().getRequest(
            url: Uri.parse('${Config.baseUrl}/members/me'),
          );

          if (result.statusCode == 200) {
            final response = jsonDecode(result.body) as Map<String, dynamic>;
            if ((response['status'] ?? 200) == 200) {
              // Token is valid, auto-login
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Home()),
                );
                return;
              }
            }
          }
        } catch (e) {
          // Token is invalid or expired, clear it and show login form
          await prefs.remove('token');
        }
      }
    } catch (e) {
      // Error checking auto-login, just show login form
      debugPrint('Auto-login check error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingAutoLogin = false;
        });
      }
    }
  }

  // ---- Login API ----
  void loginUser() async {
    setState(() => isLoading = true);

    final identifier = _loginMode == 'Use your Kanisa number'
        ? ekanisaController.text
        : email.text;

    final data = {'identifier': identifier, 'password': password.text};

    final result = await API().postRequest(
      url: Uri.parse('${Config.baseUrl}/login'),
      data: data,
    );
    final response = jsonDecode(result.body);

    if (response['status'] == 200) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('user_id', response['user']['id']);
      await prefs.setString('name', response['user']['name']);
      await prefs.setString('email', response['user']['email']);
      await prefs.setString('token', response['token']);
      if (response['user']['e_kanisa_number'] != null) {
        await prefs.setString(
          'e_kanisa_number',
          response['user']['e_kanisa_number'],
        );
      }

      API.showSnack(context, response['message'], success: true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Home()),
      );
    } else {
      API.showSnack(context, response['message'], success: false);
    }

    setState(() => isLoading = false);
  }

  // ---- Login Option Picker ----
  IconData _loginIcon(String v) {
    switch (v) {
      case 'Use your email address':
        return Icons.email_outlined;
      case 'Use your Kanisa number':
        return Icons.perm_identity_outlined;
      default:
        return Icons.lock_outline;
    }
  }

  void _openLoginPicker() {
    final options = <String>[
      'Use your email address',
      'Use your Kanisa number',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Login using',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Divider(height: 20),
              ...options.map(
                (v) => ListTile(
                  leading: Icon(_loginIcon(v), color: Color(0xFF0A1F44)),
                  title: Text(v, style: const TextStyle(fontSize: 15)),
                  trailing: v == _loginMode
                      ? const Icon(Icons.check_circle, color: Color(0xFF0A1F44))
                      : null,
                  onTap: () {
                    setState(() => _loginMode = v);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginCard() {
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
            width: 160,
            height: 160,
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
          const SizedBox(height: 24),
          const Text(
            "Welcome back to My Kanisa App",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E3A59),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "Login using",
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _openLoginPicker,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _loginIcon(_loginMode),
                        color: const Color(0xFF0A1F44),
                      ),
                      const SizedBox(width: 12),
                      Text(_loginMode, style: const TextStyle(fontSize: 15)),
                    ],
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: Colors.black54),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _loginMode == 'Use your Kanisa number'
                  ? ekanisaController
                  : email,
              decoration: InputDecoration(
                hintText: _loginMode == 'Use your Kanisa number'
                    ? "Enter your kanisa number"
                    : "Enter your email address",
                border: InputBorder.none,
                prefixIcon: Icon(
                  _loginMode == 'Use your Kanisa number'
                      ? Icons.person
                      : Icons.email,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: password,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                hintText: "Enter your password",
                border: InputBorder.none,
                prefixIcon: const Icon(
                  Icons.lock,
                  color: Colors.grey,
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.black,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (isLoading)
            SizedBox(
              width: double.infinity,
              height: 70,
              child: Center(
                child: SpinKitFadingCircle(
                  size: 108,
                  duration: const Duration(milliseconds: 3200),
                  itemBuilder: (context, index) {
                    final palette = [
                      Colors.black,
                      Color(0xFF0A1F44),
                      Colors.red,
                      Colors.green,
                    ];
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: palette[index % palette.length],
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              ),
            )
          else
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
                onPressed: loginUser,
                child: const Text(
                  "Login to your account",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
            ),
            child: const Text(
              "Forgot Password?",
              style: TextStyle(color: Color(0xFF0A1F44), fontSize: 14),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider(color: Colors.grey)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Or",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
              const Expanded(child: Divider(color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const Register()),
                ),
                child: const Text(
                  "Register",
                  style: TextStyle(
                    color: Color(0xFF0A1F44),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
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
          child: _buildLoginCard(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return DesktopScaffoldFrame(
      title: 'Login Page',
      primaryColor: const Color(0xFF35C2C1),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              child: _buildLoginCard(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking auto-login
    if (_isCheckingAutoLogin) {
      return Scaffold(
        backgroundColor: const Color(0xFFE8F4FD),
        body: Center(
          child: SpinKitFadingCircle(
            size: 64,
            duration: const Duration(milliseconds: 3200),
            itemBuilder: (context, index) {
              final palette = [
                Colors.black,
                const Color(0xFF0A1F44),
                Colors.red,
                Colors.green,
              ];
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: palette[index % palette.length],
                  shape: BoxShape.circle,
                ),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFE8F4FD),
      body: ResponsiveLayout(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }
}
