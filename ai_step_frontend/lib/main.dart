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
import 'services/auth_service.dart';
import 'services/steps_service.dart';
import 'middleware/auth_guard.dart';

// TODO: Set to false before production release!
const bool DEV_MODE = true;

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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()..initialize()),
        ChangeNotifierProxyProvider<AuthService, StepsService>(
          create: (context) => StepsService(context.read<AuthService>()),
          update: (context, auth, previous) => previous ?? StepsService(auth),
        ),
        ChangeNotifierProxyProvider<StepsService, PedometerService>(
          create: (context) => PedometerService(stepsService: context.read<StepsService>())..initialize(),
          update: (context, stepsService, previous) {
            if (previous != null) {
              // Возвращаем существующий экземпляр, просто обновляем ссылку на stepsService если нужно
              return previous;
            }
            return PedometerService(stepsService: stepsService)..initialize();
          },
        ),
      ],
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
        initialRoute: DEV_MODE ? '/home' : '/',
        routes: {
          '/': (context) => const GuestGuard(child: OnboardingScreen()),
          '/login': (context) => const GuestGuard(child: LoginScreen()),
          '/signup': (context) => const GuestGuard(child: SignUpScreen()),
          '/additional-data': (context) => DEV_MODE
              ? const AdditionalDataScreen()
              : const AuthGuard(child: AdditionalDataScreen()),
          '/home': (context) => const AuthGuard(child: HomeScreen()),
          '/profile': (context) => DEV_MODE
              ? const ProfileScreen()
              : const AuthGuard(child: ProfileScreen()),
          '/statistics': (context) => DEV_MODE
              ? const StatisticsScreen()
              : const AuthGuard(child: StatisticsScreen()),
          '/meals': (context) => DEV_MODE
              ? const MealsScreen()
              : const AuthGuard(child: MealsScreen()),
          '/water': (context) => DEV_MODE
              ? const WaterScreen()
              : const AuthGuard(child: WaterScreen()),
        },
      ),
    );
  }
}
