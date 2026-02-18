import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../models/user.dart';
import 'auth_service.dart';

class UserService {
  final http.Client httpClient;

  UserService({http.Client? httpClient})
      : httpClient = httpClient ?? _createInsecureClient();

  static http.Client _createInsecureClient() {
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  Future<String> _getToken() async {
    return AuthService.getAccessTokenWithRefresh();
  }

  Map<String, dynamic> _buildSubmitPayload(User user) {
    final derivedNames = _deriveNames(user);
    return {
      'id': user.id,
      'email': user.email,
      'firstName': derivedNames.firstName,
      'lastName': derivedNames.lastName,
      'age': user.age,
      'heightCm': user.height,
      'weightKg': user.weight,
      'gender': user.gender?.index,
      'activityLevel': user.activityLevel?.index,
      'fitnessGoal': user.goal?.index,
      'isVerified': user.isVerified,
      'createdAt': user.createdAt?.toIso8601String(),
      'calorieGoal': user.calorieGoal,
      'proteinGoal': user.proteinGoal,
      'waterGoal': user.waterGoal,
      'stepsGoal': user.stepsGoal,
    };
  }

  _NameParts _deriveNames(User user) {
    if ((user.firstName != null && user.firstName!.isNotEmpty) ||
        (user.lastName != null && user.lastName!.isNotEmpty)) {
      return _NameParts(user.firstName, user.lastName);
    }

    final displayName = user.displayName?.trim();
    if (displayName == null || displayName.isEmpty) {
      return const _NameParts(null, null);
    }

    final parts = displayName.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return _NameParts(parts.first, null);
    }
    final first = parts.first;
    final last = parts.sublist(1).join(' ');
    return _NameParts(first, last.isEmpty ? null : last);
  }

  Future<void> submitUser(User user) async {
    final uri = Uri.parse('http://192.168.43.16:8082/users/submit');
    final token = await _getToken();
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final body = jsonEncode(_buildSubmitPayload(user));

    http.Response response;
    try {
      response = await httpClient.post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
    } catch (e) {
      final insecure = _createInsecureClient();
      response = await insecure.post(uri, headers: headers, body: body)
          .timeout(const Duration(seconds: 10));
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }

    throw Exception(
        'Failed to submit user: ${response.statusCode} ${response.body}');
  }

  Future<String> uploadAvatar(int userId, File imageFile) async {
      print("-----------------------------------",);
    final uri =
        Uri.parse('http://192.168.43.16:8082/users/$userId/avatar');
    final token = await _getToken();

    final request = http.MultipartRequest('POST', uri);

    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile(
        'file',
        imageFile.readAsBytes().asStream(),
        imageFile.lengthSync(),
        filename: imageFile.path.split('/').last,
      ),
    );

    http.StreamedResponse response;
    try {
      response = await httpClient.send(request).timeout(const Duration(seconds: 30));
      print("-----------------------------------",);
    } catch (e) {
      print("----------------------------------- $e",);
      throw Exception('Failed to upload avatar: $e');
    }

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200 || response.statusCode == 201) {
      print("-----------------------------------");
      final jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
      final avatarPath = jsonResponse['avatarPath'] as String?;
      if (avatarPath == null) {
        throw Exception('Avatar path not returned from server');
      }
      return avatarPath;
    }

    throw Exception(
        'Failed to upload avatar: ${response.statusCode} $responseBody');
  }
}

class _NameParts {
  final String? firstName;
  final String? lastName;

  const _NameParts(this.firstName, this.lastName);
}
