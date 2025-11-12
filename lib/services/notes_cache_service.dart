import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/note.dart';
import '../utils/constants.dart';

class NotesCacheService {
  static const String _notesCacheKey = 'notes_cache';
  static const String _cacheTimestampKey = 'notes_cache_timestamp';

  // Save notes to cache
  Future<void> cacheNotes(List<Note> notes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = notes.map((note) => note.toJson()).toList();
      await prefs.setString(_notesCacheKey, json.encode(notesJson));
      await prefs.setString(
          _cacheTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      // Ignore errors
    }
  }

  // Get cached notes
  Future<List<Note>?> getCachedNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(_cacheTimestampKey);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      final now = DateTime.now();
      final difference = now.difference(timestamp);

      // Check if cache is still valid (within cache duration)
      if (difference.inMinutes > AppConstants.notesCacheMinutes) {
        return null; // Cache expired
      }

      final notesJson = prefs.getString(_notesCacheKey);
      if (notesJson == null) return null;

      final notesList = List<Map<String, dynamic>>.from(json.decode(notesJson));
      return notesList.map((json) => Note.fromJson(json)).toList();
    } catch (e) {
      return null;
    }
  }

  // Update single note in cache
  Future<void> updateNoteInCache(Note note) async {
    try {
      final cachedNotes = await getCachedNotes();
      if (cachedNotes == null) return;

      final index = cachedNotes.indexWhere((n) => n.id == note.id);
      if (index >= 0) {
        cachedNotes[index] = note;
      } else {
        cachedNotes.add(note);
      }

      await cacheNotes(cachedNotes);
    } catch (e) {
      // Ignore errors
    }
  }

  // Remove note from cache
  Future<void> removeNoteFromCache(String noteId) async {
    try {
      final cachedNotes = await getCachedNotes();
      if (cachedNotes == null) return;

      cachedNotes.removeWhere((note) => note.id == noteId);
      await cacheNotes(cachedNotes);
    } catch (e) {
      // Ignore errors
    }
  }

  // Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notesCacheKey);
      await prefs.remove(_cacheTimestampKey);
    } catch (e) {
      // Ignore errors
    }
  }
}

