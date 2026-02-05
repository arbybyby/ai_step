import 'package:flutter/material.dart';
import '../services/water_service.dart';
import '../models/water_info.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  final WaterService _service = WaterService();
  List<WaterInfo> _entries = [];
  bool _loading = true;
  int _target = 2000;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() { _loading = true; });
    try {
      final e = await _service.getEntries();
      setState(() {
        _entries = e;
      });
    } catch (err) {
      // ignore - show empty
      print('WaterTrackerScreen._refresh: $err');
    } finally {
      setState(() { _loading = false; });
    }
  }

  int get _consumed => _entries.fold(0, (p, e) => p + e.waterDrank);
  double get _percent => _target == 0 ? 0 : (_consumed / _target).clamp(0.0, 1.0);

  Future<void> _addAmount(int amount) async {
    try {
      await _service.add(amount);
      await _refresh();
    } catch (e) {
      print('add failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to add: $e')));
    }
  }

  Future<void> _removeAmount(int amount) async {
    try {
      await _service.remove(amount);
      await _refresh();
    } catch (e) {
      print('remove failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to remove: $e')));
    }
  }

  void _showCustomAddDialog() {
    final controller = TextEditingController();
    showDialog<void>(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Custom Amount'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (ml)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            final v = int.tryParse(controller.text);
            if (v != null && v > 0) {
              Navigator.of(ctx).pop();
              _addAmount(v);
            }
          }, child: const Text('Add'))
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Tracker'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text('$_consumed ml', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('of $_target ml', style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 12),
                      Container(
                        width: 64,
                        height: 36,
                        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(20)),
                        alignment: Alignment.center,
                        child: Text('${(_percent * 100).toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text('Quick Add', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.6,
                        children: [100,200,250,300,400,500].map((v) {
                          return ElevatedButton(
                            onPressed: () => _addAmount(v),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue.shade50, foregroundColor: Colors.blue),
                            child: Text('$v ml'),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _removeAmount(100),
                            icon: const Icon(Icons.remove, color: Colors.red),
                            label: const Text('Remove'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.red),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _addAmount(100),
                            icon: const Icon(Icons.add),
                            label: const Text('+100 ml'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          ),
                          ElevatedButton(
                            onPressed: _showCustomAddDialog,
                            child: const Icon(Icons.edit),
                            style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(12)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Today's History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_loading) const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator())),
                      if (!_loading && _entries.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No entries yet')),
                      if (!_loading && _entries.isNotEmpty)
                        ..._entries.reversed.map((e) => ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.water_drop, color: Colors.white), backgroundColor: Colors.blueAccent),
                          title: Text('${e.waterDrank} ml', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                          subtitle: Text('Entry id: ${e.id}'),
                        ))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
