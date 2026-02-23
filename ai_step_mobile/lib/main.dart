import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/onboarding_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/home_screen.dart';
import 'screens/water_tracker_screen.dart';
import 'screens/meals_tracking_screen.dart';
import 'screens/profile_screen.dart';
import 'services/auth_service.dart';
import 'services/step_storage_service.dart';
import 'services/background_sync_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Load environment variables from .env (optional file in project root)
  try {
    await dotenv.load();
    print('Loaded .env variables: ${dotenv.env.keys.join(', ')}');
  } catch (e) {
    print('No .env file found or failed to load: $e');
  }
  
  // Initialize storage services
  final storageService = StepStorageService();
  await storageService.init();
  // Initialize background sync (WorkManager) early so periodic tasks
  // can be registered and survive app restarts.
  try {
    await BackgroundSyncService.init();
  } catch (e) {
    print('Failed to init BackgroundSyncService in main: $e');
  }
  
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIStep',
      theme: ThemeData(
      ),
      home: const AuthGate(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/home_old': (context) => const MyHomePage(title: 'AI Step'),
        '/water': (context) => const WaterTrackerScreen(),
        '/meals': (context) => const MealsTrackingScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<bool> _isLoggedIn() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final logged = snapshot.data ?? false;
        return logged ? const HomeScreen() : const OnboardingScreen();
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String? _userId;
  String? _email;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _fetchMe();
  }

  Future<void> _fetchMe() async {
    try {
      final me = await AuthService.getMe();
      setState(() {
        _userId = me['userId']?.toString();
        _email = me['email']?.toString();
      });
    } catch (e) {
      // ignore errors for now (server might require auth token)
      print('Could not fetch profile: $e');
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  Future<void> _onLogoutPressed() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await AuthService.logout();
      // Ensure local storage and prefs cleared
      try {
        await StepStorageService().clear();
        print('main._onLogoutPressed: StepStorageService cleared');
      } catch (e) {
        print('main._onLogoutPressed: Failed to clear StepStorageService: $e');
      }
      final sp = await SharedPreferences.getInstance();
      try {
        await sp.clear();
        print('main._onLogoutPressed: SharedPreferences cleared');
      } catch (e) {
        print('main._onLogoutPressed: Failed to clear SharedPreferences: $e');
      }
      // Navigate to sign-in regardless of server response
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/signin');
    } catch (e) {
      print('Logout error: $e');
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Logout failed'), content: Text('Could not logout: $e'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: _isLoggingOut ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.logout),
            onPressed: _isLoggingOut ? null : _onLogoutPressed,
            tooltip: 'Logout',
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('User ID: ${_userId ?? "(not loaded)"}'),
            const SizedBox(height: 6),
            Text('Email: ${_email ?? "(not loaded)"}'),
            const SizedBox(height: 16),
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
