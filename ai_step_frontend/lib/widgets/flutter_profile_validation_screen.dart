import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';

class FlutterProfileValidationScreen extends StatefulWidget {
  const FlutterProfileValidationScreen({Key? key}) : super(key: key);

  @override
  State<FlutterProfileValidationScreen> createState() => _FlutterProfileValidationScreenState();
}

class _FlutterProfileValidationScreenState extends State<FlutterProfileValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _stepGoalController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedActivityLevel;
  
  FlutterProfileValidationResult? _currentValidation;
  bool _isValidating = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
    
    // Добавляем listeners для real-time валидации
    _nameController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
    _ageController.addListener(_onFieldChanged);
    _stepGoalController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _stepGoalController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    await profileService.loadProfile();
    
    if (profileService.profileData != null) {
      final data = profileService.profileData!;
      _nameController.text = data['firstName'] ?? '';
      _heightController.text = data['heightCm']?.toString() ?? '';
      _weightController.text = data['weightKg']?.toString() ?? '';
      _ageController.text = data['age']?.toString() ?? '';
      _stepGoalController.text = data['dailyStepGoal']?.toString() ?? '';
      _selectedGender = data['gender'];
      _selectedActivityLevel = data['activityLevel'];
      setState(() {});
    }
  }

  void _onFieldChanged() {
    // Задержка для real-time валидации
    if (!_isValidating) {
      _isValidating = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _validateCurrentData();
        }
      });
    }
  }

  Future<void> _validateCurrentData() async {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    
    final validation = await profileService.validateFlutterProfile(
      userName: _nameController.text.isEmpty ? null : _nameController.text,
      heightCm: _heightController.text.isEmpty ? null : int.tryParse(_heightController.text),
      weightKg: _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
      age: _ageController.text.isEmpty ? null : int.tryParse(_ageController.text),
      activityLevel: _selectedActivityLevel,
      gender: _selectedGender,
      dailyStepGoal: _stepGoalController.text.isEmpty ? null : int.tryParse(_stepGoalController.text),
    );

    if (mounted) {
      setState(() {
        _currentValidation = validation;
        _isValidating = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final profileService = Provider.of<ProfileService>(context, listen: false);
    
    final success = await profileService.updateFlutterProfile(
      userName: _nameController.text.isEmpty ? null : _nameController.text,
      heightCm: _heightController.text.isEmpty ? null : int.tryParse(_heightController.text),
      weightKg: _weightController.text.isEmpty ? null : double.tryParse(_weightController.text),
      age: _ageController.text.isEmpty ? null : int.tryParse(_ageController.text),
      activityLevel: _selectedActivityLevel,
      gender: _selectedGender,
      dailyStepGoal: _stepGoalController.text.isEmpty ? null : int.tryParse(_stepGoalController.text),
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: ${profileService.lastValidationError}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Validation Demo'),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<ProfileService>(
        builder: (context, profileService, child) {
          if (profileService.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Validation Status Card
                  if (_currentValidation != null)
                    _buildValidationCard(_currentValidation!),
                  
                  const SizedBox(height: 16),
                  
                  // Form Fields
                  _buildNameField(),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(child: _buildHeightField()),
                      const SizedBox(width: 16),
                      Expanded(child: _buildWeightField()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildAgeField(),
                  const SizedBox(height: 16),
                  
                  _buildGenderField(),
                  const SizedBox(height: 16),
                  
                  _buildActivityLevelField(),
                  const SizedBox(height: 16),
                  
                  _buildStepGoalField(),
                  const SizedBox(height: 24),
                  
                  // BMI Display
                  if (_currentValidation?.calculatedBMI != null)
                    _buildBMICard(),
                  
                  const SizedBox(height: 24),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: (_currentValidation?.valid == true && !profileService.isLoading)
                        ? _saveProfile
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Save Profile',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildValidationCard(FlutterProfileValidationResult validation) {
    return Card(
      color: validation.valid ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  validation.valid ? Icons.check_circle : Icons.error,
                  color: validation.valid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  validation.valid ? 'Valid' : 'Validation Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: validation.valid ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            
            if (validation.errors != null && validation.errors!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Errors:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ...validation.errors!.entries.map((e) => 
                Text('• ${e.key}: ${e.value}', style: const TextStyle(color: Colors.red))),
            ],
            
            if (validation.warnings != null && validation.warnings!.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ...validation.warnings!.entries.map((e) => 
                Text('• ${e.key}: ${e.value}', style: const TextStyle(color: Colors.orange))),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBMICard() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BMI Information', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('BMI: ${_currentValidation!.calculatedBMI!.toStringAsFixed(1)}'),
            if (_currentValidation!.bmiCategory != null)
              Text('Category: ${_currentValidation!.bmiCategory}'),
          ],
        ),
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: InputDecoration(
        labelText: 'Name',
        border: const OutlineInputBorder(),
        errorText: _getFieldError('userName'),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Name is required';
        }
        return null;
      },
    );
  }

  Widget _buildHeightField() {
    return TextFormField(
      controller: _heightController,
      decoration: InputDecoration(
        labelText: 'Height (cm)',
        border: const OutlineInputBorder(),
        errorText: _getFieldError('heightCm'),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Height is required';
        }
        final height = int.tryParse(value);
        if (height == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  Widget _buildWeightField() {
    return TextFormField(
      controller: _weightController,
      decoration: InputDecoration(
        labelText: 'Weight (kg)',
        border: const OutlineInputBorder(),
        errorText: _getFieldError('weightKg'),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Weight is required';
        }
        final weight = double.tryParse(value);
        if (weight == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  Widget _buildAgeField() {
    return TextFormField(
      controller: _ageController,
      decoration: InputDecoration(
        labelText: 'Age',
        border: const OutlineInputBorder(),
        errorText: _getFieldError('age'),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Age is required';
        }
        final age = int.tryParse(value);
        if (age == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        border: const OutlineInputBorder(),
        errorText: _getFieldError('gender'),
      ),
      items: const [
        DropdownMenuItem(value: 'MALE', child: Text('Male')),
        DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedGender = value;
        });
        _onFieldChanged();
      },
      validator: (value) {
        if (value == null) {
          return 'Gender is required';
        }
        return null;
      },
    );
  }

  Widget _buildActivityLevelField() {
    return DropdownButtonFormField<String>(
      value: _selectedActivityLevel,
      decoration: InputDecoration(
        labelText: 'Activity Level',
        border: const OutlineInputBorder(),
        errorText: _getFieldError('activityLevel'),
      ),
      items: const [
        DropdownMenuItem(value: 'LOW', child: Text('Low')),
        DropdownMenuItem(value: 'MODERATE', child: Text('Moderate')),
        DropdownMenuItem(value: 'HIGH', child: Text('High')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedActivityLevel = value;
        });
        _onFieldChanged();
      },
      validator: (value) {
        if (value == null) {
          return 'Activity level is required';
        }
        return null;
      },
    );
  }

  Widget _buildStepGoalField() {
    final profileService = Provider.of<ProfileService>(context, listen: false);
    final recommendation = profileService.getStepGoalRecommendation(
      _selectedActivityLevel,
      int.tryParse(_ageController.text),
    );

    return TextFormField(
      controller: _stepGoalController,
      decoration: InputDecoration(
        labelText: 'Daily Step Goal',
        border: const OutlineInputBorder(),
        helperText: 'Recommended: $recommendation',
        errorText: _getFieldError('dailyStepGoal'),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Step goal is required';
        }
        final goal = int.tryParse(value);
        if (goal == null) {
          return 'Invalid number';
        }
        return null;
      },
    );
  }

  String? _getFieldError(String fieldName) {
    return _currentValidation?.errors?[fieldName];
  }
}