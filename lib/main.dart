import 'dart:ui';

import 'package:devkitflutter/config/constant.dart';
import 'package:devkitflutter/widgets/keyboard_dismiss_wrapper.dart';
import 'package:devkitflutter/services/op_localization_service.dart';
import 'package:devkitflutter/services/offline_feedback_service.dart';

import 'package:devkitflutter/ui/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  // this function makes application always run in portrait mode
  WidgetsFlutterBinding.ensureInitialized();
  // Set preferred orientations synchronously for faster startup
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Initialize OP localization service (only affects OP module pages)
  await OPLocalizationService.init();
  // Initialize Hive for offline feedback storage
  await OfflineFeedbackService.init();
  runApp(const MyApp());
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  // Override behavior methods and getters like dragDevices
  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scrollBehavior: MyCustomScrollBehavior(),
      title: appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        pageTransitionsTheme: const PageTransitionsTheme(builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
        }),
      ),
      builder: (context, child) {
        // Wrap all routes with keyboard dismiss wrapper
        return KeyboardDismissWrapper(
          child: child ?? const SizedBox(),
        );
      },
      home: const SplashScreenPage(),
    );
  }
}