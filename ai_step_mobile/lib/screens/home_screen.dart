import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../providers/steps_provider.dart';
import '../models/step_data.dart';
import '../services/step_counter_service.dart';
import '../services/background_sync_service.dart';
import '../services/notification_service.dart';
import 'dart:async';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late StepCounterService _stepCounterService;
  int _currentSteps = 0;
  int _lastSyncedSteps = 0;
  bool _goalAchieved = false;
  Timer? _syncTimer;
  bool _isSyncing = false;
  bool _isLoggingOut = false;
  DateTime _lastManualSyncAttempt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize notification service
    await NotificationService().init();

    // Initialize background sync
    await BackgroundSyncService.init();
    await BackgroundSyncService.startPeriodicSync();

    // Load initial data
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      print('HomeScreen._initializeServices: Starting initial sync and fetch...');
      try {
        // First sync local data to backend
        print('HomeScreen._initializeServices: Calling BackgroundSyncService.syncNow...');
        await BackgroundSyncService.syncNow();
        print('HomeScreen._initializeServices: BackgroundSyncService.syncNow completed');
        
        // Then fetch from backend to update provider state
        print('HomeScreen._initializeServices: Calling fetchCurrentDaySteps...');
        await ref.read(currentDayStepsProvider.notifier).fetchCurrentDaySteps();
        print('HomeScreen._initializeServices: fetchCurrentDaySteps completed - provider updated');
        
        // Immediately read the updated value and update local state
        print('HomeScreen._initializeServices: Reading provider value...');
        final providerState = ref.read(currentDayStepsProvider);
        print('HomeScreen._initializeServices: Provider state type: ${providerState.runtimeType}');
        providerState.whenData((data) async {
          if (data != null && mounted) {
            print('HomeScreen._initializeServices: Got data from provider: ${data.stepsCount} steps');
            setState(() {
              _currentSteps = data.stepsCount;
              _lastSyncedSteps = data.stepsCount;
            });
            print('HomeScreen._initializeServices: Updated _currentSteps to ${data.stepsCount}');

            // Initialize step counter after we have last-known steps
            _stepCounterService = StepCounterService();
            await _stepCounterService.init(_onStepCountChanged, initialSteps: _currentSteps);
            print('HomeScreen._initializeServices: StepCounterService initialized with initialSteps=$_currentSteps');
          } else {
            print('HomeScreen._initializeServices: Provider data is null');
            // Initialize step counter with default 0 if no provider data
            _stepCounterService = StepCounterService();
            await _stepCounterService.init(_onStepCountChanged);
            print('HomeScreen._initializeServices: StepCounterService initialized with default initialSteps=0');
          }
        });
      } catch (e, stackTrace) {
        print('HomeScreen._initializeServices: initial sync/fetch failed: $e');
        print('HomeScreen._initializeServices: stackTrace: $stackTrace');
      }
    }

    // Set up frequent periodic sync timer (every 10 seconds) to keep data fresh
    _syncTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (!mounted) {
        print('HomeScreen: Periodic sync tick skipped - widget not mounted');
        return;
      }
      print('\n=== HomeScreen: Periodic sync tick START (10s interval) ===');
      print('HomeScreen: Current steps: $_currentSteps, LastSynced: $_lastSyncedSteps');
      
      if (_isSyncing) {
        print('HomeScreen: Sync already in progress, skipping this tick');
        return;
      }
      
      _isSyncing = true;
      print('HomeScreen: Starting periodic sync cycle...');
      
      try {
        // First, try to flush any queued local steps to backend
        print('HomeScreen: Step 1 - Syncing to backend...');
        try {
          await BackgroundSyncService.syncNow();
          print('HomeScreen: BackgroundSyncService.syncNow SUCCESS');
        } catch (e, stackTrace) {
          print('HomeScreen: periodic syncNow FAILED: $e');
          print('HomeScreen: syncNow stackTrace: $stackTrace');
        }

        // Then, fetch latest from backend and update provider state
        print('HomeScreen: Step 2 - Fetching from backend via provider...');
        try {
          await ref.read(currentDayStepsProvider.notifier).fetchCurrentDaySteps();
          print('HomeScreen: fetchCurrentDaySteps SUCCESS - provider state updated');
          
          // Read updated value and update local state
          final providerState = ref.read(currentDayStepsProvider);
          providerState.whenData((data) {
            if (data != null && mounted) {
              setState(() {
                _currentSteps = data.stepsCount;
                _lastSyncedSteps = data.stepsCount;
              });
              print('HomeScreen: Periodic sync updated _currentSteps to ${data.stepsCount}');
            }
          });
        } catch (e, stackTrace) {
          print('HomeScreen: periodic fetch FAILED: $e');
          print('HomeScreen: fetch stackTrace: $stackTrace');
        }
      } finally {
        _isSyncing = false;
        print('=== HomeScreen: Periodic sync tick END ===\n');
      }
    });
  }

  void _onStepCountChanged(int steps) {
    print('HomeScreen._onStepCountChanged: Steps changed to $steps (previous: $_currentSteps)');
    setState(() {
      _currentSteps = steps;
    });

    // Check if goal is achieved
    final goal = 400;
    if (!_goalAchieved && steps >= goal) {
      _goalAchieved = true;
      NotificationService().showGoalAchievedNotification(goal);
    }

    // Update steps in provider
    ref.read(currentDayStepsProvider.notifier).updateSteps(steps);

    // Attempt an immediate sync if we have a significant increase,
    // but throttle to avoid spamming sync calls.
    final now = DateTime.now();
    final stepsDiff = steps - _lastSyncedSteps;
    if (stepsDiff >= 10 && now.difference(_lastManualSyncAttempt) > const Duration(seconds: 30)) {
      print('HomeScreen._onStepCountChanged: Triggering immediate sync (diff: $stepsDiff)');
      _lastManualSyncAttempt = now;
      _syncSteps();
    }
  }

  Future<void> _syncSteps() async {
    print('HomeScreen._syncSteps: Syncing $_currentSteps steps');
    try {
      await ref.read(currentDayStepsProvider.notifier).syncSteps(_currentSteps);
      setState(() {
        _lastSyncedSteps = _currentSteps;
      });
      print('HomeScreen._syncSteps: Sync successful, lastSyncedSteps updated to $_lastSyncedSteps');
    } catch (e) {
      print('HomeScreen._syncSteps: Sync failed: $e');
      NotificationService().showSyncErrorNotification();
      // Don't update _lastSyncedSteps on failure, will retry on next timer tick
    }
  }


  @override
  void dispose() {
    _syncTimer?.cancel();
    _stepCounterService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final goalAsync = ref.watch(goalProvider);
    final lastSyncAsync = ref.watch(lastSyncTimeProvider);

    // Listen to provider updates and update local state
    ref.listen<AsyncValue<StepData?>>(currentDayStepsProvider, (previous, next) {
      print('HomeScreen: currentDayStepsProvider changed - previous: ${previous?.value?.stepsCount}, next: ${next.value?.stepsCount}');
      next.whenData((data) {
        if (data != null && mounted) {
          print('HomeScreen: Updating _currentSteps from ${_currentSteps} to ${data.stepsCount}');
          setState(() {
            _currentSteps = data.stepsCount;
            _lastSyncedSteps = data.stepsCount;
          });
        }
      });
    });

    // Gradient background and modern card layout to match design
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F8A58), Color(0xFF12B76A)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header: greeting + actions
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Good Evening, Kirill!',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Keep Moving!',
                                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),

                        // action buttons
                        Column(
                          children: [
                            Row(
                              children: [
                                _roundIconButton(icon: Icons.notifications_none, onPressed: () {}),
                                const SizedBox(width: 12),
                                _roundIconButton(
                                  icon: _isLoggingOut ? Icons.hourglass_empty : Icons.logout,
                                  onPressed: _isLoggingOut ? null : _onLogoutPressed,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Main card
                    goalAsync.when(
                      data: (goal) => _buildMainCard(goal, lastSyncAsync),
                      loading: () => const SizedBox(height: 260, child: Center(child: CircularProgressIndicator(color: Colors.white))),
                      error: (e, s) => const SizedBox(),
                    ),

                    const SizedBox(height: 18),

                    // Small stats row (Calories, Distance)
                    Row(
                      children: [
                        Expanded(child: _statCard(icon: Icons.local_fire_department, title: '0 kcal', subtitle: 'Calories')),
                        const SizedBox(width: 12),
                        Expanded(child: _statCard(icon: Icons.straighten, title: '0.0 km', subtitle: 'Distance')),
                      ],
                    ),

                    const SizedBox(height: 12),
                    _statCard(icon: Icons.timer, title: '0 min', subtitle: 'Active Minutes', fullWidth: true),

                    const SizedBox(height: 16),

                    // Weekly progress
                    _weeklyProgressCard(),

                    const SizedBox(height: 16),

                    // Tiles: Meals / Water
                    Row(
                      children: [
                        Expanded(child: _tileCard(icon: Icons.restaurant, title: 'Meals', subtitle: 'Track food')),
                        const SizedBox(width: 12),
                        Expanded(child: _tileCard(icon: Icons.opacity, title: 'Water', subtitle: 'Stay hydrated')),
                      ],
                    ),

                    const SizedBox(height: 16),

                    _dailyTipCard(),

                    const SizedBox(height: 14),

                    _encouragementCard(goalAsync),

                    const SizedBox(height: 120), // leave space for floating profile
                  ],
                ),
              ),

              // Floating Profile button bottom-right
              Positioned(
                right: 18,
                bottom: 18,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/profile'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Color(0xFF0F8A58)),
                        SizedBox(width: 8),
                        Text('Profile', style: TextStyle(color: Color(0xFF0F8A58), fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roundIconButton({required IconData icon, required VoidCallback? onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildMainCard(int goal, AsyncValue<DateTime?> lastSyncAsync) {
    final progress = (goal == 0) ? 0.0 : (_currentSteps / goal).clamp(0.0, 1.0);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6))],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
      child: Column(
        children: [
          // "Synced with server" pill removed

          const SizedBox(height: 18),

          // circular steps indicator
          SizedBox(
            height: 200,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      backgroundColor: const Color(0xFFF0FBF6),
                      valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF0F8A58)),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_walk, color: const Color(0xFF0F8A58), size: 28),
                      const SizedBox(height: 6),
                      Text(_currentSteps.toString(), style: const TextStyle(fontSize: 48, color: Color(0xFF0F8A58), fontWeight: FontWeight.w800)),
                      const SizedBox(height: 6),
                      Text('of $goal steps', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          // thin progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress, minHeight: 8, backgroundColor: const Color(0xFFF0FBF6), valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFFCCF6E3))),
          ),

          const SizedBox(height: 12),

          Text('${(progress * 100).toStringAsFixed(0)}% of daily goal', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey[700])),

          const SizedBox(height: 12),

          // status pill removed
        ],
      ),
    );
  }

  Widget _statCard({required IconData icon, required String title, required String subtitle, bool fullWidth = false}) {
    return Container(
      height: fullWidth ? 84 : 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: const Color(0xFFEFFBF6), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: const Color(0xFF0F8A58)),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(title, style: const TextStyle(color: Color(0xFF0F8A58), fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(subtitle, style: TextStyle(color: Colors.grey[700])),
            ],
          )
        ],
      ),
    );
  }

  Widget _weeklyProgressCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Weekly Progress', style: TextStyle(fontWeight: FontWeight.w800)),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) => Container(width: 36, height: 28, decoration: BoxDecoration(color: const Color(0xFFEFFBF6), borderRadius: BorderRadius.circular(12))),),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Mon', style: TextStyle(color: Colors.grey)), Text('Tue', style: TextStyle(color: Colors.grey)), Text('Wed', style: TextStyle(color: Colors.grey)), Text('Thu', style: TextStyle(color: Colors.grey)), Text('Fri', style: TextStyle(color: Colors.grey)), Text('Sat', style: TextStyle(color: Colors.grey)), Text('Sun', style: TextStyle(color: Color(0xFF0F8A58), fontWeight: FontWeight.w800))],),
        ],
      ),
    );
  }

  Widget _tileCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      height: 110,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))]),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEFFBF6), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: const Color(0xFF0F8A58))),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(title, style: TextStyle(color: Color(0xFF0F8A58), fontWeight: FontWeight.w800)), const SizedBox(height: 6), Text(subtitle, style: TextStyle(color: Colors.grey[700]))])
        ],
      ),
    );
  }

  Widget _dailyTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0F8A58), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 6))]),
      child: Row(
        children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF12B76A), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.stairs, color: Colors.white)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Daily Tip', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700)), SizedBox(height: 6), Text('Take the stairs instead of the elevator', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800))])),
        ],
      ),
    );
  }

  Widget _encouragementCard(AsyncValue<int> goalAsync) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: const Color(0xFF0AB36A), borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))]),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('🔥 Keep Going!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)), SizedBox(height: 8), Text("You're only 400 steps away from your goal!", style: TextStyle(color: Colors.white70))])),
          Container(width: 72, height: 72, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(36)), child: Icon(Icons.emoji_events, color: Colors.white, size: 36)),
        ],
      ),
    );
  }

  Future<void> _onLogoutPressed() async {
    print('HomeScreen._onLogoutPressed: Starting logout...');
    if (_isLoggingOut) {
      print('HomeScreen._onLogoutPressed: Already logging out, ignoring');
      return;
    }
    
    if (!mounted) {
      print('HomeScreen._onLogoutPressed: Widget not mounted');
      return;
    }
    
    setState(() => _isLoggingOut = true);
    
    try {
      print('HomeScreen._onLogoutPressed: Calling AuthService.logout()');
      await AuthService.logout();
      print('HomeScreen._onLogoutPressed: AuthService.logout() completed');
      
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('isLoggedIn', false);
      print('HomeScreen._onLogoutPressed: Updated SharedPreferences');
      
      if (!mounted) {
        print('HomeScreen._onLogoutPressed: Widget unmounted after logout');
        return;
      }
      
      print('HomeScreen._onLogoutPressed: Navigating to /signin');
      Navigator.of(context).pushReplacementNamed('/signin');
    } catch (e, stackTrace) {
      print('HomeScreen._onLogoutPressed: logout FAILED: $e');
      print('HomeScreen._onLogoutPressed: stackTrace: $stackTrace');
      
      if (!mounted) return;
      
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Logout failed'),
          content: Text('Could not logout: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        print('HomeScreen._onLogoutPressed: Reset _isLoggingOut flag');
      }
    }
  }





}
