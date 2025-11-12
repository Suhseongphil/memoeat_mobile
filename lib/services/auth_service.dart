import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/supabase.dart';
import '../models/user_approval.dart';

class AuthService {
  final _supabase = SupabaseConfig.client;

  // Sign Up
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Create user approval record
      final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? '';
      final isAutoApproved = email == adminEmail;

      await _supabase.from('user_approvals').insert({
        'user_id': response.user!.id,
        'email': email,
        'is_approved': isAutoApproved,
        'approved_at': isAutoApproved ? DateTime.now().toIso8601String() : null,
      });
    }

  }

  // Sign In
  Future<void> signIn({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      // Check if user is approved
      try {
        final approval = await _supabase
            .from('user_approvals')
            .select()
            .eq('user_id', response.user!.id)
            .maybeSingle();

        // If no approval record exists, create one with auto-approval for admin
        if (approval == null) {
          final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? '';
          final isAutoApproved = email == adminEmail;
          
          await _supabase.from('user_approvals').insert({
            'user_id': response.user!.id,
            'email': email,
            'is_approved': isAutoApproved,
            'approved_at': isAutoApproved ? DateTime.now().toIso8601String() : null,
          });

          if (!isAutoApproved) {
            await _supabase.auth.signOut();
            throw Exception('사용자 승인이 필요합니다.');
          }
        } else if (approval['is_approved'] != true) {
          await _supabase.auth.signOut();
          throw Exception('사용자 승인이 필요합니다.');
        }
      } catch (e) {
        // If it's already an Exception, rethrow it
        if (e is Exception && e.toString().contains('사용자 승인이 필요합니다')) {
          rethrow;
        }
        // For other errors (like network issues), sign out and throw
        await _supabase.auth.signOut();
        rethrow;
      }
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Get Current User
  dynamic getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  // Get User Approval
  Future<UserApproval?> getUserApproval(String userId) async {
    try {
      final response = await _supabase
          .from('user_approvals')
          .select()
          .eq('user_id', userId)
          .single();

      return UserApproval.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // Check if user is admin
  Future<bool> isAdmin(String userId) async {
    try {
      final approval = await getUserApproval(userId);
      if (approval == null) return false;

      final adminEmail = dotenv.env['ADMIN_EMAIL'] ?? '';
      return approval.email == adminEmail;
    } catch (e) {
      return false;
    }
  }

  // Auth State Stream
  Stream get authStateChanges => _supabase.auth.onAuthStateChange;
}

