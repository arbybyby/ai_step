import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_config.dart';

class AdditionalDataScreen extends StatefulWidget {
  const AdditionalDataScreen({super.key});

  @override
  State<AdditionalDataScreen> createState() => _AdditionalDataScreenState();
}

class _AdditionalDataScreenState extends State<AdditionalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = 'male';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null || token.isEmpty) {
        if (mounted) {
          _showSnackBar('Session expired. Please log in again.');
          Navigator.of(context)
              .pushNamedAndRemoveUntil('/login', (route) => false);
        }
        return;
      }

      final response = await http.post(
        apiUri('/auth/additional-data'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'height': double.tryParse(
            _heightController.text.replaceAll(',', '.'),
          ),
          'weight': double.tryParse(
            _weightController.text.replaceAll(',', '.'),
          ),
          'gender': _selectedGender,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final user = payload['user'];
        if (user is Map<String, dynamic>) {
          await prefs.setString('auth_user', jsonEncode(user));
        }

        if (!mounted) return;

        _showSnackBar('Profile updated!', isSuccess: true);
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (route) => false);
      } else {
        final message =
            _parseErrorMessage(response.body) ??
            'Could not save data. Please try again.';
        _showSnackBar(message);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Could not reach the server. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? _parseErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final message = decoded['message'] ?? decoded['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? const Color(0xFF6A4C9C) : null,
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 16),
      filled: true,
      fillColor: Colors.white.withOpacity(0.95),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: Color(0xFF6A4C9C), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF9D7FE5), Color(0xFFB39DDB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () =>
                        Navigator.of(context).pushReplacementNamed('/signup'),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Complete\nYour Profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We\'ll tailor your insights\nbased on your body data',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 48),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _heightController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: _decoration('Height (cm)'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final normalized = value.replaceAll(
                                      ',',
                                      '.',
                                    );
                                    final parsed = double.tryParse(normalized);
                                    if (parsed == null || parsed <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _weightController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: _decoration('Weight (kg)'),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final normalized = value.replaceAll(
                                      ',',
                                      '.',
                                    );
                                    final parsed = double.tryParse(normalized);
                                    if (parsed == null || parsed <= 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedGender,
                            decoration: _decoration('Gender'),
                            items: const [
                              DropdownMenuItem(
                                value: 'male',
                                child: Text('Male'),
                              ),
                              DropdownMenuItem(
                                value: 'female',
                                child: Text('Female'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedGender = value);
                              }
                            },
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isSubmitting ? null : _handleContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6A4C9C),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                disabledBackgroundColor: const Color(
                                  0xFF6A4C9C,
                                ).withOpacity(0.6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Continue',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
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
}
