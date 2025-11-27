import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pcea_church/components/constant.dart';
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/components/welcome.dart';
import 'package:pcea_church/config/server.dart';
import 'package:pcea_church/method/api.dart';
import 'package:pcea_church/screen/dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _lottieController;
  bool copAnimated = false;
  bool animateCafeText = false;
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);
    _determineStartupDestination();

    // Fixed splash timing
    Future.delayed(const Duration(seconds: 2), () {
      copAnimated = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 800), () {
        animateCafeText = true;
        setState(() {});
      });
    });
  }

  Future<void> _determineStartupDestination() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null || token.isEmpty) {
      setState(() => _checkingSession = false);
      return;
    }

    try {
      final response = await API().getRequest(
        url: Uri.parse('${Config.baseUrl}/members/me'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 200) {
          final member = data['member'] ?? {};
          if (member['name'] != null) prefs.setString('name', member['name']);
          if (member['email'] != null)
            prefs.setString('email', member['email']);
          if (member['congregation'] != null) {
            prefs.setString('congregation_name', member['congregation']);
          }
          if (member['role'] != null) prefs.setString('role', member['role']);
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const Home()),
          );
          return;
        }
      }
    } catch (_) {}

    await prefs.remove('token');
    setState(() => _checkingSession = false);
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  Widget _buildSplashStack(BuildContext context, {double? heightOverride}) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final containerHeight = heightOverride ?? screenHeight;

    final isDesktop = screenWidth >= 900;

    return Stack(
      children: [
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          height: copAnimated ? containerHeight / 1.9 : containerHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(copAnimated ? 40.0 : 0.0),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Visibility(
                visible: !copAnimated,
                child: Lottie.asset(
                  'assets/Church.json',
                  controller: _lottieController,
                  height: isDesktop
                      ? containerHeight * 0.6
                      : containerHeight * 0.45,
                  onLoaded: (composition) {
                    final fasterDuration = Duration(
                      milliseconds: (composition.duration.inMilliseconds / 1.5)
                          .round(),
                    );
                    _lottieController
                      ..duration = fasterDuration
                      ..forward();
                  },
                ),
              ),
              Visibility(
                visible: copAnimated,
                child: Center(
                  child: Image.asset(
                    'assets/icon.png',
                    height: isDesktop ? 220.0 : 190.0,
                    width: isDesktop ? 220.0 : 190.0,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      opacity: animateCafeText ? 1 : 0,
                      duration: const Duration(seconds: 1),
                      child: Text(
                        'Welcome To PCEA.',
                        style: TextStyle(
                          fontSize: isDesktop ? 48.0 : 40.0,
                          color: cafeBrown,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 16 : 12),
                    AnimatedOpacity(
                      opacity: animateCafeText ? 1 : 0,
                      duration: const Duration(seconds: 1),
                      child: Text(
                        'Faith  •  Love  •  Hope',
                        style: TextStyle(
                          fontSize: isDesktop ? 28.0 : 24.0,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Visibility(
          visible: copAnimated && !_checkingSession,
          child: const _BottomPart(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F44),
      body: ResponsiveLayout(
        mobile: _buildSplashStack(context),
        desktop: DesktopScaffoldFrame(
          backgroundColor: const Color(0xFF0A1F44),
          title: '',
          primaryColor: const Color(0xFF35C2C1),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: _buildSplashStack(context, heightOverride: 700),
            ),
          ),
        ),
      ),
    );
  }
}

class _BottomPart extends StatelessWidget {
  const _BottomPart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 80.0 : 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Grow with Us in Faith & Community',
              style: TextStyle(
                fontSize: isDesktop ? 28.0 : 24.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 30.0 : 25.0),
            Text(
              'Stay connected with your congregation — anytime, anywhere.',
              style: TextStyle(
                fontSize: isDesktop ? 17.0 : 15.0,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 50.0 : 40.0),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                  );
                },
                child: Container(
                  height: isDesktop ? 100.0 : 85.0,
                  width: isDesktop ? 100.0 : 85.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.0),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: isDesktop ? 60.0 : 50.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(height: isDesktop ? 60.0 : 50.0),
          ],
        ),
      ),
    );
  }
}
