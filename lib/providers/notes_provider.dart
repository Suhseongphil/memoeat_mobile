import 'package:flutter/foundation.dart';
import '../services/notes_service.dart';
import '../services/notes_cache_service.dart';
import '../models/note.dart';

class NotesProvider with ChangeNotifier {
  final NotesService _notesService = NotesService();
  final NotesCacheService _cacheService = NotesCacheService();

  List<Note> _notes = [];
  List<Note> _favoriteNotes = [];
  List<Note> _deletedNotes = [];
  bool _isLoading = false;
  String? _error;

  List<Note> get notes => _notes;
  List<Note> get favoriteNotes => _favoriteNotes;
  List<Note> get deletedNotes => _deletedNotes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load notes
  Future<void> loadNotes({String? folderId, bool useCache = true}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Try to load from cache first if enabled
      if (useCache) {
        final cachedNotes = await _cacheService.getCachedNotes();
        if (cachedNotes != null) {
          _notes = cachedNotes;
          _isLoading = false;
          notifyListeners();
        }
      }

      // Load from server
      _notes = await _notesService.getNotes(folderId: folderId);
      
      // Update cache
      await _cacheService.cacheNotes(_notes);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      // If error and no cached data, show error
      if (_notes.isEmpty) {
        _error = e.toString();
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load favorite notes
  Future<void> loadFavoriteNotes() async {
    try {
      _favoriteNotes = await _notesService.getFavoriteNotes();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Load deleted notes
  Future<void> loadDeletedNotes() async {
    try {
      _deletedNotes = await _notesService.getDeletedNotes();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Create note
  Future<Note?> createNote({String? title, String? folderId, bool skipReload = false}) async {
    try {
      final note = await _notesService.createNote(
        title: title,
        folderId: folderId,
      );
      
      // Add to local cache immediately
      _notes.add(note);
      await _cacheService.updateNoteInCache(note);
      notifyListeners();
      
      // Reload from server only if not skipping
      if (!skipReload) {
        await loadNotes(folderId: folderId, useCache: false);
      }
      
      return note;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update note
  Future<bool> updateNote(String noteId, NoteData data, {bool skipReload = false}) async {
    try {
      final updatedNote = await _notesService.updateNote(noteId, data);
      
      // Update local cache immediately for instant UI update
      final noteIndex = _notes.indexWhere((n) => n.id == noteId);
      if (noteIndex >= 0) {
        _notes[noteIndex] = updatedNote;
        await _cacheService.updateNoteInCache(updatedNote);
        notifyListeners();
      }
      
      // Update favorite notes if needed
      final favoriteIndex = _favoriteNotes.indexWhere((n) => n.id == noteId);
      if (favoriteIndex >= 0) {
        _favoriteNotes[favoriteIndex] = updatedNote;
        notifyListeners();
      }
      
      // Reload from server only if not skipping (for sync)
      if (!skipReload) {
        await loadNotes(useCache: false);
        await loadFavoriteNotes();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete note
  Future<bool> deleteNote(String noteId, {bool skipReload = false}) async {
    try {
      await _notesService.deleteNote(noteId);
      
      // Remove from local cache immediately
      _notes.removeWhere((n) => n.id == noteId);
      _favoriteNotes.removeWhere((n) => n.id == noteId);
      await _cacheService.removeNoteFromCache(noteId);
      notifyListeners();
      
      // Reload from server only if not skipping
      if (!skipReload) {
        await loadNotes(useCache: false);
        await loadFavoriteNotes();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Restore note
  Future<bool> restoreNote(String noteId) async {
    try {
      await _notesService.restoreNote(noteId);
      await loadNotes();
      await loadDeletedNotes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Permanently delete note
  Future<bool> permanentlyDeleteNote(String noteId) async {
    try {
      await _notesService.permanentlyDeleteNote(noteId);
      await loadDeletedNotes();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle favorite
  Future<bool> toggleFavorite(String noteId, {bool skipReload = false}) async {
    try {
      final updatedNote = await _notesService.toggleFavorite(noteId);
      
      // Update local cache immediately
      final noteIndex = _notes.indexWhere((n) => n.id == noteId);
      if (noteIndex >= 0) {
        _notes[noteIndex] = updatedNote;
        await _cacheService.updateNoteInCache(updatedNote);
      }
      
      // Update favorite list
      if (updatedNote.data.isFavorite) {
        if (!_favoriteNotes.any((n) => n.id == noteId)) {
          _favoriteNotes.add(updatedNote);
        }
      } else {
        _favoriteNotes.removeWhere((n) => n.id == noteId);
      }
      notifyListeners();
      
      // Reload from server only if not skipping
      if (!skipReload) {
        await loadNotes(useCache: false);
        await loadFavoriteNotes();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Move note
  Future<bool> moveNote(String noteId, String? folderId) async {
    try {
      final updatedNote = await _notesService.moveNote(noteId, folderId);
      
      // Update local cache immediately
      final noteIndex = _notes.indexWhere((n) => n.id == noteId);
      if (noteIndex >= 0) {
        _notes[noteIndex] = updatedNote;
        await _cacheService.updateNoteInCache(updatedNote);
        notifyListeners();
      }
      
      // Reload from server
      await loadNotes(useCache: false);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update note order
  Future<bool> updateNoteOrder(String noteId, int newOrder) async {
    try {
      await _notesService.updateNoteOrder(noteId, newOrder);
      
      // Update local cache immediately
      final noteIndex = _notes.indexWhere((n) => n.id == noteId);
      if (noteIndex >= 0) {
        final note = _notes[noteIndex];
        final updatedNote = note.copyWith(
          data: note.data.copyWith(order: newOrder),
        );
        _notes[noteIndex] = updatedNote;
        await _cacheService.updateNoteInCache(updatedNote);
        _notes.sort((a, b) => a.data.order.compareTo(b.data.order));
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Search notes
  Future<List<Note>> searchNotes(String query) async {
    try {
      return await _notesService.searchNotes(query);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

