import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../models/auth_user.dart';

class AuthService {
  AuthService({sb.SupabaseClient? supabaseClient})
    : _supabase = supabaseClient ?? sb.Supabase.instance.client;

  final sb.SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleSignInInitialized = false;

  // Stream of auth state changes
  Stream<AuthUser?> get authStateChanges =>
      _supabase.auth.onAuthStateChange.map<AuthUser?>(
        (state) => _mapSupabaseUser(state.session?.user),
      );

  // Current user
  AuthUser? get currentUser => _mapSupabaseUser(_supabase.auth.currentUser);

  // Sign in with Email and Password
  Future<void> signInWithEmail(String email, String password) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Sign up with Email and Password
  Future<void> signUpWithEmail(String email, String password) async {
    await _supabase.auth.signUp(email: email, password: password);
  }

  // Sign in with Google
  Future<void> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google Sign-In did not return an idToken.');
      }

      await _supabase.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return;
      }
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await Future.wait([
      _supabase.auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) {
      return;
    }

    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  AuthUser? _mapSupabaseUser(sb.User? user) {
    if (user == null) {
      return null;
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final appMetadata = user.appMetadata;
    final providers = appMetadata['providers'] as List<dynamic>? ?? const <dynamic>[];

    return AuthUser(
      id: user.id,
      email: user.email,
      displayName:
          (metadata['full_name'] as String?) ??
          (metadata['name'] as String?) ??
          (metadata['display_name'] as String?),
      photoUrl: metadata['avatar_url'] as String?,
      providerIds: providers
          .whereType<String>()
          .where((provider) => provider.isNotEmpty)
          .toSet()
          .toList(),
    );
  }
}
