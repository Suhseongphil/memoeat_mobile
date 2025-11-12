import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase.dart';
import '../utils/constants.dart';

class PreferencesService {
  final _supabase = SupabaseConfig.client;

  // Get preferences from Supabase
  Future<Map<String, dynamic>> getPreferences() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // Return default preferences from local storage
      return await _getLocalPreferences();
    }

    try {
      final response = await _supabase
          .from('user_approvals')
          .select('preferences')
          .eq('user_id', user.id)
          .single();

      final prefs = response['preferences'] as Map<String, dynamic>?;
      return prefs ?? await _getLocalPreferences();
    } catch (e) {
      return await _getLocalPreferences();
    }
  }

  // Update preferences in Supabase
  Future<void> updatePreferences(Map<String, dynamic> preferences) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      // Save to local storage only
      await _saveLocalPreferences(preferences);
      return;
    }

    try {
      await _supabase
          .from('user_approvals')
          .update({'preferences': preferences})
          .eq('user_id', user.id);

      // Also save to local storage for quick access
      await _saveLocalPreferences(preferences);
    } catch (e) {
      // Fallback to local storage
      await _saveLocalPreferences(preferences);
    }
  }

  // Get theme
  Future<String> getTheme() async {
    final prefs = await getPreferences();
    return prefs['theme'] as String? ?? 'light';
  }

  // Set theme
  Future<void> setTheme(String theme) async {
    final prefs = await getPreferences();
    prefs['theme'] = theme;
    await updatePreferences(prefs);
  }

  // Get sidebar position
  Future<String> getSidebarPosition() async {
    final prefs = await getPreferences();
    return prefs['sidebarPosition'] as String? ?? 'left';
  }

  // Set sidebar position
  Future<void> setSidebarPosition(String position) async {
    final prefs = await getPreferences();
    prefs['sidebarPosition'] = position;
    await updatePreferences(prefs);
  }

  // Get remember me
  Future<bool> getRememberMe() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.rememberMeKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Set remember me
  Future<void> setRememberMe(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.rememberMeKey, value);
    } catch (e) {
      // Ignore errors
    }
  }

  // Local storage helpers
  Future<Map<String, dynamic>> _getLocalPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final theme = prefs.getString(AppConstants.themeKey) ?? 'light';
      final sidebarPosition = prefs.getString(AppConstants.sidebarPositionKey) ?? 'left';

      return {
        'theme': theme,
        'sidebarPosition': sidebarPosition,
      };
    } catch (e) {
      // Return default preferences if SharedPreferences is not available
      return {
        'theme': 'light',
        'sidebarPosition': 'left',
      };
    }
  }

  Future<void> _saveLocalPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (preferences.containsKey('theme')) {
        await prefs.setString(AppConstants.themeKey, preferences['theme'] as String);
      }
      
      if (preferences.containsKey('sidebarPosition')) {
        await prefs.setString(
          AppConstants.sidebarPositionKey,
          preferences['sidebarPosition'] as String,
        );
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

