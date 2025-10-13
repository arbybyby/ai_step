import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'auth/additional_data_screen.dart';
import 'auth/login_screen.dart';
import 'auth/onboarding_screen.dart';
import 'auth/sign_up_screen.dart';
import 'homepage/home_screen.dart';
import 'homepage/profile_screen.dart';
import 'homepage/statistics_screen.dart';
import 'homepage/meals_tracking_screen.dart';
import 'homepage/water_tracking_screen.dart';
import 'services/pedometer_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PedometerService()..initialize(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AI-Step',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE23C64),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          scaffoldBackgroundColor: Colors.white,
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const OnboardingScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignUpScreen(),
          '/additional-data': (context) => const AdditionalDataScreen(),
          '/home': (context) => const HomeScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/statistics': (context) => const StatisticsScreen(),
          '/meals': (context) => const MealsScreen(),
          '/water': (context) => const WaterScreen(),
        },
      ),
    );
  }
}
