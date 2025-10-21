const String backendBaseUrl = String.fromEnvironment(
  'BACKEND_URL',
  defaultValue: 'http://192.168.42.162:8080',
);

const String googleClientId = String.fromEnvironment(
  'GOOGLE_CLIENT_ID',
  defaultValue:
      '37802022899-a4o3o6qfoglpa0vju8amoubvpkg3ncjk.apps.googleusercontent.com',
);

bool get isGoogleSignInConfigured =>
    !googleClientId.contains('YOUR_GOOGLE_CLIENT_ID');

Uri apiUri(String path) {
  final normalizedPath = path.startsWith('/') ? path : '/$path';
  return Uri.parse('$backendBaseUrl$normalizedPath');
}
