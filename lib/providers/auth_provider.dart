import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  User? _user;
  AppUser? _appUser;
  bool _loading = false;
  String? _error;

  AuthProvider(this._authService) {
    _authService.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        _appUser = await _authService.getAppUser(user.uid);
      } else {
        _appUser = null;
      }
      notifyListeners();
    });
  }

  User? get user => _user;
  AppUser? get appUser => _appUser;
  bool get loading => _loading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.signInWithEmail(email, password);
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _translateError(e.code);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    required String city,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        city: city,
      );
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _translateError(e.code);
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _translateError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Geen account gevonden met dit e-mailadres.';
      case 'wrong-password':
        return 'Ongeldig wachtwoord.';
      case 'email-already-in-use':
        return 'Dit e-mailadres is al in gebruik.';
      case 'weak-password':
        return 'Wachtwoord is te zwak (minimaal 6 tekens).';
      case 'invalid-email':
        return 'Ongeldig e-mailadres.';
      case 'too-many-requests':
        return 'Te veel pogingen. Probeer later opnieuw.';
      default:
        return 'Er is een fout opgetreden. Probeer opnieuw.';
    }
  }
}
