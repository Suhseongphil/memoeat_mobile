import 'package:flutter/foundation.dart';
import '../config/supabase.dart';
import '../models/note.dart';
import 'package:uuid/uuid.dart';

class NotesService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  // Get all notes for user
  Future<List<Note>> getNotes({String? folderId, bool includeDeleted = false}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final response = await _supabase
          .from('notes')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      List<Note> notes = (response as List)
          .map((json) => Note.fromJson(json))
          .toList();

      // Filter deleted items on client side if needed
      if (!includeDeleted) {
        notes = notes.where((note) => note.deletedAt == null).toList();
      }

      // Filter by folder if specified
      if (folderId != null) {
        notes = notes.where((note) => note.data.folderId == folderId).toList();
      } else if (folderId == null && !includeDeleted) {
        // If folderId is null, get root notes (folderId is null)
        notes = notes.where((note) => note.data.folderId == null).toList();
      }

      // Sort by order
      notes.sort((a, b) => a.data.order.compareTo(b.data.order));

      debugPrint('Loaded ${notes.length} notes for user ${user.id}');
      return notes;
    } catch (e) {
      debugPrint('Error loading notes: $e');
      rethrow;
    }
  }

  // Get single note
  Future<Note?> getNote(String noteId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final response = await _supabase
          .from('notes')
          .select()
          .eq('id', noteId)
          .eq('user_id', user.id)
          .single();

      return Note.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create note
  Future<Note> createNote({
    String? title,
    String? folderId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final noteId = _uuid.v4();

    // Get max order for folder
    final existingNotes = await getNotes(folderId: folderId);
    final maxOrder = existingNotes.isEmpty
        ? 0
        : existingNotes.map((n) => n.data.order).reduce((a, b) => a > b ? a : b);

    final noteData = NoteData(
      title: title ?? '제목 없음',
      content: '',
      folderId: folderId,
      isFavorite: false,
      order: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    );

    final response = await _supabase.from('notes').insert({
      'id': noteId,
      'user_id': user.id,
      'data': noteData.toJson(),
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    }).select().single();

    return Note.fromJson(response);
  }

  // Update note
  Future<Note> updateNote(String noteId, NoteData data) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final updatedData = data.copyWith(updatedAt: DateTime.now());

    final response = await _supabase
        .from('notes')
        .update({
          'data': updatedData.toJson(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', noteId)
        .eq('user_id', user.id)
        .select()
        .single();

    return Note.fromJson(response);
  }

  // Delete note (soft delete)
  Future<void> deleteNote(String noteId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase
        .from('notes')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', noteId)
        .eq('user_id', user.id);
  }

  // Restore note
  Future<void> restoreNote(String noteId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase
        .from('notes')
        .update({'deleted_at': null})
        .eq('id', noteId)
        .eq('user_id', user.id);
  }

  // Permanently delete note
  Future<void> permanentlyDeleteNote(String noteId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase
        .from('notes')
        .delete()
        .eq('id', noteId)
        .eq('user_id', user.id);
  }

  // Toggle favorite
  Future<Note> toggleFavorite(String noteId) async {
    final note = await getNote(noteId);
    if (note == null) throw Exception('Note not found');

    final updatedData = note.data.copyWith(
      isFavorite: !note.data.isFavorite,
    );

    return await updateNote(noteId, updatedData);
  }

  // Move note to folder
  Future<Note> moveNote(String noteId, String? folderId) async {
    final note = await getNote(noteId);
    if (note == null) throw Exception('Note not found');

    // Get max order for target folder
    final existingNotes = await getNotes(folderId: folderId);
    final maxOrder = existingNotes.isEmpty
        ? 0
        : existingNotes.map((n) => n.data.order).reduce((a, b) => a > b ? a : b);

    final updatedData = note.data.copyWith(
      folderId: folderId,
      order: maxOrder + 1,
    );

    return await updateNote(noteId, updatedData);
  }

  // Update note order
  Future<void> updateNoteOrder(String noteId, int newOrder) async {
    final note = await getNote(noteId);
    if (note == null) throw Exception('Note not found');

    final updatedData = note.data.copyWith(order: newOrder);
    await updateNote(noteId, updatedData);
  }

  // Search notes
  Future<List<Note>> searchNotes(String query) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final allNotes = await getNotes(includeDeleted: false);
    final lowerQuery = query.toLowerCase();

    return allNotes.where((note) {
      final title = note.data.title.toLowerCase();
      final content = note.data.content.toLowerCase();
      return title.contains(lowerQuery) || content.contains(lowerQuery);
    }).toList();
  }

  // Get favorite notes
  Future<List<Note>> getFavoriteNotes() async {
    final allNotes = await getNotes(includeDeleted: false);
    return allNotes.where((note) => note.data.isFavorite).toList();
  }

  // Get deleted notes
  Future<List<Note>> getDeletedNotes() async {
    return await getNotes(includeDeleted: true)
        .then((notes) => notes.where((note) => note.deletedAt != null).toList());
  }
}

