import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/library/sk_onboarding_screen/sk_onboarding_model.dart';
import 'package:devkitflutter/library/sk_onboarding_screen/sk_onboarding_screen.dart';
import 'package:devkitflutter/ui/domain_login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({Key? key}) : super(key: key);

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  final pages = [
    SkOnboardingModel(
      title: 'Welcome to Efeedor',
      description:
          'Digitizing healthcare experience and quality.',
      titleColor: efeedorBrandGreen,
      descripColor: const Color(0xFF666666),
      imageAssetPath: 'assets/images/onboarding_images1.png',
    ),
    SkOnboardingModel(
      title: 'Access Your Hospital',
      description:
          'Enter your hospital domain and request access.',
      titleColor: efeedorBrandGreen,
      descripColor: const Color(0xFF666666),
      imageAssetPath: 'assets/images/onboarding_images2.png',
    ),
    SkOnboardingModel(
      title: 'Secure Login',
      description:
          'username and password recording and managing data.',
      titleColor: efeedorBrandGreen,
      descripColor: const Color(0xFF666666),
      imageAssetPath: 'assets/images/onboarding_images3.png',
    ),
    SkOnboardingModel(
      title: 'Collect. Analyze. Improve.',
      description:
          'Capture data, track performance, and drive improvement.',
      titleColor: efeedorBrandGreen,
      descripColor: const Color(0xFF666666),
      imageAssetPath: 'assets/images/onboarding_images4.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      child: SKOnboardingScreen(
        bgColor: Colors.white,
        themeColor: efeedorBrandGreen,
        pages: pages,
        skipClicked: (value) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasOnboarded', true);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const DomainLoginPage()));
        },
        getStartedClicked: (value) async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasOnboarded', true);
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const DomainLoginPage()));
        },
      ),
    ));
  }
}
