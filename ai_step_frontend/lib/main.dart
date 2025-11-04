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
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const AuthSplashScreen(),
          '/': (context) => const GuestGuard(child: OnboardingScreen()),
          '/login': (context) => const GuestGuard(child: LoginScreen()),
          '/signup': (context) => const GuestGuard(child: SignUpScreen()),
          '/additional-data': (context) => const AuthGuard(child: AdditionalDataScreen()),
          '/home': (context) => const AuthGuard(child: HomeScreen()),
          '/profile': (context) => const AuthGuard(child: ProfileScreen()),
          '/statistics': (context) => const AuthGuard(child: StatisticsScreen()),
          '/meals': (context) => const AuthGuard(child: MealsScreen()),
          '/water': (context) => const AuthGuard(child: WaterScreen()),
        },
      ),
    );
  }
}

// Splash screen that waits for AuthService to initialize
class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen> {
  bool _hasNavigated = false;

  void _navigate(AuthService authService) {
    if (_hasNavigated || !mounted) return;
    
    print('===== AuthSplashScreen _navigate =====');
    print('isLoading: ${authService.isLoading}');
    print('isAuthenticated: ${authService.isAuthenticated}');
    
    if (!authService.isLoading) {
      _hasNavigated = true;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        
        print('Navigating to: ${authService.isAuthenticated ? "/home" : "/"}');
        
        if (authService.isAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/home');
        } else {
          Navigator.of(context).pushReplacementNamed('/');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        _navigate(authService);
        
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
        );
      },
    );
  }
}
