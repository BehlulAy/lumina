import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to authentication state changes (cached stream instance)
  late final Stream<User?> authStateChanges = _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      final message = _mapAuthExceptionToTurkish(e.code);
      throw Exception(message);
    } catch (e) {
      throw Exception('Giriş yapılırken beklenmedik bir hata oluştu.');
    }
  }

  // Register with email and password, and update user display name
  Future<User?> signUpWithEmailAndPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final User? user = result.user;
      if (user != null) {
        // Update user display name
        await user.updateDisplayName(name.trim());
        await user.reload();
        return _auth.currentUser;
      }
      return user;
    } on FirebaseAuthException catch (e) {
      final message = _mapAuthExceptionToTurkish(e.code);
      throw Exception(message);
    } catch (e) {
      throw Exception('Kayıt olunurken beklenmedik bir hata oluştu.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }



  // Helper method to convert Firebase Auth exceptions to Turkish user-friendly errors
  String _mapAuthExceptionToTurkish(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Geçersiz e-posta adresi biçimi.';
      case 'user-disabled':
        return 'Bu kullanıcı hesabı askıya alınmış.';
      case 'user-not-found':
        return 'Bu e-posta adresine ait bir kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre girdiniz.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.';
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'operation-not-allowed':
        return 'E-posta/Şifre ile giriş yöntemi etkinleştirilmemiş.';
      case 'invalid-credential':
        return 'E-posta adresi veya şifre hatalı.';
      case 'channel-error':
        return 'Gerekli bilgiler eksik veya hatalı.';
      default:
        return 'Bir kimlik doğrulama hatası oluştu: $code';
    }
  }
}
