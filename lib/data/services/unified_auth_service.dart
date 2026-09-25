import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';

/// RF-003 — Serviço de autenticação unificada (Firebase Auth).
///
/// Email/senha + Google, mesma identidade do web. O ID token do Firebase
/// é usado como credencial Bearer nas rotas da API (ponte firebaseAuth).
class UnifiedAuthService {
  UnifiedAuthService(this._auth);

  final FirebaseAuth _auth;

  User? get currentUser => _auth.currentUser;

  /// Login email/senha. Retorna o ID token ou null em caso de falha.
  Future<String?> loginWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final token = await credential.user?.getIdToken();
      return token;
    } on FirebaseAuthException catch (e) {
      developer.log('loginWithEmail falhou: ${e.code}', name: 'auth');
      return null;
    }
  }

  /// Registro email/senha com nome de exibição.
  Future<String?> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(displayName);
      final token = await credential.user?.getIdToken();
      return token;
    } on FirebaseAuthException catch (e) {
      developer.log('registerWithEmail falhou: ${e.code}', name: 'auth');
      return null;
    }
  }

  /// Login com Google (popup via sign-in provider nativo).
  ///
  /// Requer google_sign_in configurado; sem ele, usa o provedor web/popup
  /// suportado pela plataforma. Retorna o ID token ou null.
  Future<String?> loginWithGoogle() async {
    try {
      final provider = GoogleAuthProvider();
      final credential = await _auth.signInWithProvider(provider);
      final token = await credential.user?.getIdToken();
      return token;
    } on FirebaseAuthException catch (e) {
      developer.log('loginWithGoogle falhou: ${e.code}', name: 'auth');
      return null;
    } on UnimplementedError {
      return null;
    }
  }

  /// ID token atual (renova se expirado) — usar como Bearer nas chamadas API.
  Future<String?> currentIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Logout.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Stream de mudança de sessão (login/logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();
}
