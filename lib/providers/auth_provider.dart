import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/preferences_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final PreferencesService _preferencesService = PreferencesService();

  dynamic _user;
  bool _isLoading = false;
  String? _error;

  dynamic get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _user = _authService.getCurrentUser();
    notifyListeners();

    // Listen to auth state changes
    _authService.authStateChanges.listen((state) {
      _user = (state as dynamic).session?.user;
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUp(
        email: email,
        password: password,
      );

      // After signup, user needs to be approved
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _preferencesService.setRememberMe(rememberMe);
      
      await _authService.signIn(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );

      _user = _authService.getCurrentUser();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      // Supabase AuthException 처리
      final message = error.message;
      
      // 사용자 친화적인 메시지로 변환
      if (message.contains('Invalid login credentials') || 
          message.contains('invalid_credentials')) {
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      } else if (message.contains('Email not confirmed')) {
        return '이메일 인증이 필요합니다.';
      } else if (message.contains('User already registered')) {
        return '이미 등록된 이메일입니다.';
      } else if (message.contains('Password should be at least')) {
        return '비밀번호는 최소 6자 이상이어야 합니다.';
      } else if (message.contains('User not found')) {
        return '등록되지 않은 사용자입니다.';
      }
      
      // 기본적으로 원본 메시지 반환 (한글이 포함된 경우)
      return message;
    } else if (error is Exception) {
      final message = error.toString().replaceAll('Exception: ', '');
      return message;
    } else {
      return error.toString();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _user = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.resetPassword(email);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = _getErrorMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

