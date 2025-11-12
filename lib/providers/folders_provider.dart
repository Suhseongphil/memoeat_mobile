import 'package:flutter/foundation.dart';
import '../services/folders_service.dart';
import '../models/folder.dart';

class FoldersProvider with ChangeNotifier {
  final FoldersService _foldersService = FoldersService();

  List<Folder> _folders = [];
  List<Folder> _deletedFolders = [];
  bool _isLoading = false;
  String? _error;

  List<Folder> get folders => _folders;
  List<Folder> get deletedFolders => _deletedFolders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load folders
  Future<void> loadFolders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _folders = await _foldersService.getFolders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load deleted folders
  Future<void> loadDeletedFolders() async {
    try {
      _deletedFolders = await _foldersService.getDeletedFolders();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get folder tree
  Future<List<Folder>> getFolderTree({String? parentId}) async {
    try {
      return await _foldersService.getFolderTree(parentId: parentId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Create folder
  Future<Folder?> createFolder({
    required String name,
    String? parentId,
  }) async {
    try {
      final folder = await _foldersService.createFolder(
        name: name,
        parentId: parentId,
      );
      await loadFolders();
      return folder;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Update folder
  Future<bool> updateFolder(String folderId, FolderData data) async {
    try {
      await _foldersService.updateFolder(folderId, data);
      await loadFolders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete folder
  Future<bool> deleteFolder(String folderId) async {
    try {
      await _foldersService.deleteFolder(folderId);
      await loadFolders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Restore folder
  Future<bool> restoreFolder(String folderId) async {
    try {
      await _foldersService.restoreFolder(folderId);
      await loadFolders();
      await loadDeletedFolders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Permanently delete folder
  Future<bool> permanentlyDeleteFolder(String folderId) async {
    try {
      await _foldersService.permanentlyDeleteFolder(folderId);
      await loadDeletedFolders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Move folder
  Future<bool> moveFolder(String folderId, String? parentId) async {
    try {
      await _foldersService.moveFolder(folderId, parentId);
      await loadFolders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

