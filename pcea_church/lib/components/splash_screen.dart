import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:pcea_church/components/constant.dart';
import 'package:pcea_church/components/welcome.dart';

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

  @override
  void initState() {
    super.initState();
    _lottieController = AnimationController(vsync: this);

    // Fixed splash timing (always ~2s, regardless of Lottie length)
    Future.delayed(const Duration(seconds: 2), () {
      copAnimated = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 800), () {
        animateCafeText = true;
        setState(() {});
      });
    });
  }

  @override
  void dispose() {
    _lottieController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Color(0xFF0A1F44),
      body: Stack(
        children: [
          // Top animated container
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            height: copAnimated ? screenHeight / 1.9 : screenHeight,
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
                // Show Lottie before transition
                Visibility(
                  visible: !copAnimated,
                  child: Lottie.asset(
                    'assets/Church.json',
                    controller: _lottieController,
                    onLoaded: (composition) {
                      // Speed up the animation (~1.5x faster)
                      final fasterDuration = Duration(
                        milliseconds:
                            (composition.duration.inMilliseconds / 1.5).round(),
                      );
                      _lottieController
                        ..duration = fasterDuration
                        ..forward();
                    },
                  ),
                ),
                // Show logo after transition
                Visibility(
                  visible: copAnimated,
                  child: Image.asset(
                    'assets/icon.png',
                    height: 190.0,
                    width: 190.0,
                  ),
                ),
                // Animated welcome text
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        opacity: animateCafeText ? 1 : 0,
                        duration: const Duration(seconds: 1),
                        child: const Text(
                          'Welcome To PCEA.',
                          style: TextStyle(
                            fontSize: 40.0,
                            color: cafeBrown,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedOpacity(
                        opacity: animateCafeText ? 1 : 0,
                        duration: const Duration(seconds: 1),
                        child: Text(
                          'Faith  •  Love  •  Hope',
                          style: TextStyle(
                            fontSize: 24.0,
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

          // Bottom text & navigation
          Visibility(visible: copAnimated, child: const _BottomPart()),
        ],
      ),
    );
  }
}

class _BottomPart extends StatelessWidget {
  const _BottomPart({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Grow with Us in Faith & Community',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25.0),
            Text(
              'Stay connected with your congregation — anytime, anywhere.',
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.white,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40.0),
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
                  height: 85.0,
                  width: 85.0,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.0),
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 50.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 50.0),
          ],
        ),
      ),
    );
  }
}
