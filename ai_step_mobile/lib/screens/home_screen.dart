import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // Set up periodic sync timer (every 1 minute)
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (mounted && _currentSteps > _lastSyncedSteps) {
        await _syncSteps();
      }
    });
  }

  void _onStepCountChanged(int steps) {
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
  }

  Future<void> _syncSteps() async {
    try {
      await ref.read(currentDayStepsProvider.notifier).syncSteps(_currentSteps);
      setState(() {
        _lastSyncedSteps = _currentSteps;
      });
    } catch (e) {
      NotificationService().showSyncErrorNotification();
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
