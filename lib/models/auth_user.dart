class AuthUser {
  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.providerIds = const <String>[],
  });

  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final List<String> providerIds;
}

