class User {
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isEmailVerified;

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isEmailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'isEmailVerified': isEmailVerified,
    };
  }

  String get fullName => '$firstName $lastName';
}

class AuthResponse {
  final String token;
  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final bool isEmailVerified;

  AuthResponse({
    required this.token,
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isEmailVerified,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? json['jwt'] ?? '',
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }
}

class LoginRequest {
  final String email;
  final String password;

  LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'password': password,
    };
  }
}

class AuthResult {
  final bool success;
  final String message;

  AuthResult.success(this.message) : success = true;
  AuthResult.error(this.message) : success = false;
}