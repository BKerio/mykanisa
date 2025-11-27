import 'package:flutter/material.dart';
import 'package:pcea_church/components/responsive_layout.dart';
import 'package:pcea_church/screen/login.dart';
import 'package:pcea_church/screen/member_onboard.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    const Color darkBlue = Color(0xFF0A1F44);

    return Scaffold(
      backgroundColor: darkBlue,
      body: ResponsiveLayout(
        mobile: _buildMobileView(context, currentYear, darkBlue),
        desktop: _buildDesktopView(context, currentYear, darkBlue),
      ),
    );
  }

  Widget _buildMobileView(BuildContext context, int year, Color darkBlue) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: Column(
        children: [
          Flexible(
            flex: 5,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              child: Image.asset(
                "assets/img-3.png",
                width: size.width,
                fit: BoxFit.cover,
                height: size.height * 0.35,
              ),
            ),
          ),
          SizedBox(height: size.height * 0.03),
          _buildLogo(size: 90),
          SizedBox(height: size.height * 0.03),
          _buildHeadline(fontSize: 22),
          SizedBox(height: size.height * 0.01),
          _buildSubtitle(fontSize: 14),
          SizedBox(height: size.height * 0.04),
          _buildPrimaryButton(
            context: context,
            label: "Login into your Account",
            icon: Icons.login_rounded,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Login()),
            ),
          ),
          SizedBox(height: size.height * 0.015),
          _buildPrimaryButton(
            context: context,
            label: "Church member onboarding",
            icon: Icons.person_add_alt,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const Register()),
            ),
          ),
          const Spacer(),
          _buildFooter(year),
        ],
      ),
    );
  }

  Widget _buildDesktopView(BuildContext context, int year, Color darkBlue) {
    final size = MediaQuery.of(context).size;
    return DesktopScaffoldFrame(
      backgroundColor: darkBlue,
      title: '',
      primaryColor: const Color(0xFF35C2C1),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size.width * 0.05),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(48),
                  child: Image.asset(
                    "assets/img-3.png",
                    fit: BoxFit.cover,
                    height: size.height * 0.8,
                  ),
                ),
              ),
              SizedBox(width: size.width * 0.04),
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLogo(size: 120),
                    SizedBox(height: size.height * 0.03),
                    _buildHeadline(fontSize: 32, textAlign: TextAlign.left),
                    SizedBox(height: size.height * 0.015),
                    _buildSubtitle(fontSize: 18, textAlign: TextAlign.left),
                    SizedBox(height: size.height * 0.04),
                    _buildPrimaryButton(
                      context: context,
                      label: "Login into your Account",
                      icon: Icons.login_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Login()),
                      ),
                    ),
                    SizedBox(height: size.height * 0.015),
                    _buildPrimaryButton(
                      context: context,
                      label: "Church member onboarding",
                      icon: Icons.person_add_alt,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Register()),
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                    _buildFooter(year),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo({double size = 90}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Image.asset(
        "assets/icon.png",
        height: size,
        width: size,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildHeadline({
    double fontSize = 22,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Text(
      "Presbyterian Church of East Africa",
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSubtitle({
    double fontSize = 14,
    TextAlign textAlign = TextAlign.center,
  }) {
    return Text(
      "Your Gateway to Seamless Church Management",
      textAlign: textAlign,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        fontStyle: FontStyle.italic,
        color: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final size = MediaQuery.of(context).size;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: size.width * 0.05, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(int year) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        "© $year PCEA Church Application | All rights reserved",
        style: const TextStyle(fontSize: 12, color: Colors.white70),
      ),
    );
  }
}
