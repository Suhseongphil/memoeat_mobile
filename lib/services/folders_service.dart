import 'package:flutter/foundation.dart';
import '../config/supabase.dart';
import '../models/folder.dart';
import 'package:uuid/uuid.dart';

class FoldersService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  // Get all folders for user
  Future<List<Folder>> getFolders({bool includeDeleted = false}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final response = await _supabase
          .from('folders')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      final folders = (response as List)
          .map((json) => Folder.fromJson(json))
          .toList();

      // Filter deleted items on client side if needed
      final filteredFolders = includeDeleted
          ? folders
          : folders.where((folder) => folder.deletedAt == null).toList();

      debugPrint('Loaded ${filteredFolders.length} folders for user ${user.id}');
      return filteredFolders;
    } catch (e) {
      debugPrint('Error loading folders: $e');
      rethrow;
    }
  }

  // Get folder tree (nested structure)
  Future<List<Folder>> getFolderTree({String? parentId}) async {
    final allFolders = await getFolders();
    
    if (parentId == null) {
      return allFolders.where((f) => f.data.parentId == null).toList()
        ..sort((a, b) => a.data.order.compareTo(b.data.order));
    } else {
      return allFolders.where((f) => f.data.parentId == parentId).toList()
        ..sort((a, b) => a.data.order.compareTo(b.data.order));
    }
  }

  // Get single folder
  Future<Folder?> getFolder(String folderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      final response = await _supabase
          .from('folders')
          .select()
          .eq('id', folderId)
          .eq('user_id', user.id)
          .single();

      return Folder.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Create folder
  Future<Folder> createFolder({
    required String name,
    String? parentId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Check for circular reference
    if (parentId != null) {
      final canMove = await _canMoveToFolder(parentId, null);
      if (!canMove) {
        throw Exception('순환 참조를 방지할 수 없습니다.');
      }
    }

    final now = DateTime.now();
    final folderId = _uuid.v4();

    // Get max order for parent
    final existingFolders = await getFolderTree(parentId: parentId);
    final maxOrder = existingFolders.isEmpty
        ? 0
        : existingFolders.map((f) => f.data.order).reduce((a, b) => a > b ? a : b);

    final folderData = FolderData(
      name: name,
      parentId: parentId,
      order: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    );

    final response = await _supabase.from('folders').insert({
      'id': folderId,
      'user_id': user.id,
      'data': folderData.toJson(),
      'created_at': now.toIso8601String(),
    }).select().single();

    return Folder.fromJson(response);
  }

  // Update folder
  Future<Folder> updateFolder(String folderId, FolderData data) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final updatedData = data.copyWith(updatedAt: DateTime.now());

    final response = await _supabase
        .from('folders')
        .update({
          'data': updatedData.toJson(),
        })
        .eq('id', folderId)
        .eq('user_id', user.id)
        .select()
        .single();

    return Folder.fromJson(response);
  }

  // Delete folder (soft delete, recursive)
  Future<void> deleteFolder(String folderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Recursively delete child folders
    final childFolders = await getFolderTree(parentId: folderId);
    for (final child in childFolders) {
      await deleteFolder(child.id);
    }

    // Delete the folder itself
    await _supabase
        .from('folders')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('id', folderId)
        .eq('user_id', user.id);
  }

  // Restore folder
  Future<void> restoreFolder(String folderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _supabase
        .from('folders')
        .update({'deleted_at': null})
        .eq('id', folderId)
        .eq('user_id', user.id);
  }

  // Permanently delete folder
  Future<void> permanentlyDeleteFolder(String folderId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // Recursively delete child folders
    final childFolders = await getFolderTree(parentId: folderId);
    for (final child in childFolders) {
      await permanentlyDeleteFolder(child.id);
    }

    await _supabase
        .from('folders')
        .delete()
        .eq('id', folderId)
        .eq('user_id', user.id);
  }

  // Move folder
  Future<Folder> moveFolder(String folderId, String? parentId) async {
    final folder = await getFolder(folderId);
    if (folder == null) throw Exception('Folder not found');

    // Check for circular reference
    if (parentId != null) {
      final canMove = await _canMoveToFolder(parentId, folderId);
      if (!canMove) {
        throw Exception('순환 참조를 방지할 수 없습니다.');
      }
    }

    // Get max order for target parent
    final existingFolders = await getFolderTree(parentId: parentId);
    final maxOrder = existingFolders.isEmpty
        ? 0
        : existingFolders.map((f) => f.data.order).reduce((a, b) => a > b ? a : b);

    final updatedData = folder.data.copyWith(
      parentId: parentId,
      order: maxOrder + 1,
    );

    return await updateFolder(folderId, updatedData);
  }

  // Update folder order
  Future<void> updateFolderOrder(String folderId, int newOrder) async {
    final folder = await getFolder(folderId);
    if (folder == null) throw Exception('Folder not found');

    final updatedData = folder.data.copyWith(order: newOrder);
    await updateFolder(folderId, updatedData);
  }

  // Check if can move to folder (prevent circular reference)
  Future<bool> _canMoveToFolder(String targetParentId, String? movingFolderId) async {
    if (movingFolderId == null) return true;
    if (targetParentId == movingFolderId) return false;

    final targetFolder = await getFolder(targetParentId);
    if (targetFolder == null) return true;

    // Check if target is a child of moving folder
    String? currentParentId = targetFolder.data.parentId;
    while (currentParentId != null) {
      if (currentParentId == movingFolderId) return false;
      final parent = await getFolder(currentParentId);
      if (parent == null) break;
      currentParentId = parent.data.parentId;
    }

    return true;
  }

  // Get deleted folders
  Future<List<Folder>> getDeletedFolders() async {
    return await getFolders(includeDeleted: true)
        .then((folders) => folders.where((f) => f.deletedAt != null).toList());
  }
}

