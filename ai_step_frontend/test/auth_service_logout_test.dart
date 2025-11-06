import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_step_frontend/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService logout', () {
    test('should clear all SharedPreferences on logout', () async {
      // Set up fake SharedPreferences
      SharedPreferences.setMockInitialValues({'some_key': 'some_value', 'auth_token': 'token', 'auth_user': 'user'});
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getKeys().isNotEmpty, true);

      final authService = AuthService();
      await authService.logout();

      final prefsAfter = await SharedPreferences.getInstance();
      expect(prefsAfter.getKeys().isEmpty, true);
    });
  });
}
