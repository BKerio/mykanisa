import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/dashboard_factory.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  SharedPreferences? preferences;
  String username = '';
  String email = '';
  int userId = 0;
  String congregationName = '';
  String role = '';
  bool isLoading = true;
  bool hasError = false;

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
    _loadUserData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      preferences = await SharedPreferences.getInstance();
      setState(() {
        username = preferences?.getString('name') ?? '';
        email = preferences?.getString('email') ?? '';
        userId = preferences?.getInt('user_id') ?? 0;
        role = preferences?.getString('role') ?? 'member';
        congregationName = preferences?.getString('congregation_name') ?? '';
      });

      await _fetchMemberData();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Future<void> _fetchMemberData() async {
    try {
      final result = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );

      if (result.statusCode == 200) {
        final response = jsonDecode(result.body);

        if (response['status'] == 200 && response['member'] != null) {
          final member = response['member'];
          role = member['role'] ?? 'member';
          setState(() {
            congregationName = member['congregation'] ?? '';
          });
          if (preferences != null) {
            await preferences!.setString('congregation_name', congregationName);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching member data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingUI();
    }

    if (hasError) {
      return _buildErrorUI();
    }

    final dashboard = DashboardFactory.createDashboard(role);
    return dashboard;
  }

  Widget _buildLoadingUI() {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(color: Colors.white54),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/icon.png',
                width: 90,
                height: 90,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),

              const Text(
                'My Kanisa App',
                style: TextStyle(
                  color: Color(0xFF004D40),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 15),
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A1F44)),
                ),
              ),

              const SizedBox(height: 25),
              Text(
                'Loading your dashboard, $username',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 8),
              const Text(
                '“Serving through faith and fellowship”',
                style: TextStyle(
                  color: Colors.black,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 30),
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 70,
            ),
            const SizedBox(height: 20),
            const Text(
              "Oops! Connection Issue",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "We couldn’t load your dashboard.\nPlease check your connection and try again.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 15),
            ),
            const SizedBox(height: 25),
            ElevatedButton.icon(
              onPressed: _loadUserData,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                "Retry",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
