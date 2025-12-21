import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../providers/steps_provider.dart';
import '../services/step_counter_service.dart';
import '../services/background_sync_service.dart';
import '../services/notification_service.dart';
import 'dart:async';
import 'package:intl/intl.dart';

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
  bool _isLoggingOut = false;
  DateTime _lastManualSyncAttempt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    // Initialize step counter
    _stepCounterService = StepCounterService();
    await _stepCounterService.init(_onStepCountChanged);

    // Initialize notification service
    await NotificationService().init();

    // Initialize background sync
    await BackgroundSyncService.init();
    await BackgroundSyncService.startPeriodicSync();

    // Load initial data
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      ref.read(currentDayStepsProvider.notifier).fetchCurrentDaySteps();
    }

    // Set up frequent periodic sync timer (every 15 seconds)
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      print('HomeScreen: Sync timer triggered. Current: $_currentSteps, LastSynced: $_lastSyncedSteps');
      if (mounted && _currentSteps > _lastSyncedSteps) {
        print('HomeScreen: Attempting sync...');
        await _syncSteps();
      } else {
        print('HomeScreen: No sync needed - steps already synced or no new steps');
      }
    });
  }

  void _onStepCountChanged(int steps) {
    print('HomeScreen._onStepCountChanged: Steps changed to $steps (previous: $_currentSteps)');
    setState(() {
      _currentSteps = steps;
    });

    // Check if goal is achieved
    final goal = 10000;
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

  Future<void> _manualSync() async {
    if (!mounted) return;
    await _syncSteps();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Steps synced successfully!')),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Steps'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _manualSync,
            tooltip: 'Sync now',
          ),
          IconButton(
            icon: _isLoggingOut ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.logout),
            onPressed: _isLoggingOut ? null : _onLogoutPressed,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Date display
              Text(
                DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),

              // Steps count display
              goalAsync.when(
                data: (goal) => _buildStepsDisplay(goal),
                loading: () =>
                    const CircularProgressIndicator(),
                error: (error, st) => Text('Error: $error'),
              ),

              const SizedBox(height: 40),

              // Progress bar
              goalAsync.when(
                data: (goal) => _buildProgressBar(goal),
                loading: () =>
                    const CircularProgressIndicator(),
                error: (error, st) => Text('Error: $error'),
              ),

              const SizedBox(height: 40),

              // Last sync time
              lastSyncAsync.when(
                data: (lastSync) => _buildSyncInfo(lastSync),
                loading: () => const SizedBox(),
                error: (error, st) => const SizedBox(),
              ),

              const SizedBox(height: 20),

              // Status messages
              _buildStatusMessage(),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLogoutPressed() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    try {
      await AuthService.logout();
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('isLoggedIn', false);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/signin');
    } catch (e) {
      print('HomeScreen._onLogoutPressed: logout failed: $e');
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (ctx) => AlertDialog(title: const Text('Logout failed'), content: Text('Could not logout: $e'), actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK'))]));
    } finally {
      if (mounted) setState(() => _isLoggingOut = false);
    }
  }

  Widget _buildStepsDisplay(int goal) {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.1),
            border: Border.all(
              color: Colors.blue,
              width: 4,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _currentSteps.toString(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'steps',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Goal: $goal steps',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildProgressBar(int goal) {
    final progress = (_currentSteps / goal).clamp(0.0, 1.0);
    final remaining = goal - _currentSteps;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? Colors.green : Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              remaining <= 0
                  ? 'Goal reached!'
                  : '$remaining steps remaining',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: remaining <= 0 ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSyncInfo(DateTime? lastSync) {
    if (lastSync == null) {
      return const SizedBox();
    }

    final timeAgo = _getTimeAgoString(lastSync);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_done,
          size: 16,
          color: Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          'Last synced: $timeAgo',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMessage() {
    if (_currentSteps > _lastSyncedSteps) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Unsync steps: ${_currentSteps - _lastSyncedSteps}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      );
    }

    if (_goalAchieved) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Daily goal achieved! 🎉',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox();
  }

  String _getTimeAgoString(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
