import 'dart:async';
import 'package:uuid/uuid.dart';
import '../services/network_service.dart';
import '../services/offline_queue_service.dart';
import '../services/notes_service.dart';
import '../models/note.dart';

class SyncService {
  static SyncService? _instance;
  final NetworkService _networkService = NetworkService();
  final OfflineQueueService _queueService = OfflineQueueService();
  final NotesService _notesService = NotesService();
  final _uuid = const Uuid();
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService._internal();

  factory SyncService() {
    _instance ??= SyncService._internal();
    return _instance!;
  }

  // Start periodic sync
  void startPeriodicSync({Duration interval = const Duration(seconds: 30)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (_) => syncQueue());
  }

  // Stop periodic sync
  void stopPeriodicSync() {
    _syncTimer?.cancel();
  }

  // Sync queue when online
  Future<void> syncQueue() async {
    if (_isSyncing) return;
    if (!_networkService.isOnline) return;

    _isSyncing = true;
    try {
      final queue = await _queueService.getQueue();
      if (queue.isEmpty) return;

      for (final item in queue) {
        try {
          switch (item.type) {
            case 'update':
              if (item.data != null) {
                final noteData = NoteData.fromJson(item.data!);
                await _notesService.updateNote(item.noteId, noteData);
                await _queueService.removeFromQueue(item.id);
              }
              break;
            case 'create':
              if (item.data != null) {
                final noteData = NoteData.fromJson(item.data!);
                await _notesService.createNote(
                  title: noteData.title,
                  folderId: noteData.folderId,
                );
                await _queueService.removeFromQueue(item.id);
              }
              break;
            case 'delete':
              await _notesService.deleteNote(item.noteId);
              await _queueService.removeFromQueue(item.id);
              break;
          }
        } catch (e) {
          // Increment retry count
          await _queueService.incrementRetryCount(item.id);
          
          // Remove if retry count exceeds max (e.g., 5)
          if (item.retryCount >= 5) {
            await _queueService.removeFromQueue(item.id);
          }
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  // Add update to queue
  Future<void> queueUpdate(String noteId, NoteData data) async {
    final item = OfflineQueueItem(
      id: _uuid.v4(),
      type: 'update',
      noteId: noteId,
      data: data.toJson(),
      timestamp: DateTime.now(),
    );
    await _queueService.addToQueue(item);
    
    // Try to sync immediately if online
    if (_networkService.isOnline) {
      await syncQueue();
    }
  }

  // Add create to queue
  Future<void> queueCreate(NoteData data) async {
    final item = OfflineQueueItem(
      id: _uuid.v4(),
      type: 'create',
      noteId: _uuid.v4(), // Temporary ID
      data: data.toJson(),
      timestamp: DateTime.now(),
    );
    await _queueService.addToQueue(item);
    
    // Try to sync immediately if online
    if (_networkService.isOnline) {
      await syncQueue();
    }
  }

  // Add delete to queue
  Future<void> queueDelete(String noteId) async {
    final item = OfflineQueueItem(
      id: _uuid.v4(),
      type: 'delete',
      noteId: noteId,
      timestamp: DateTime.now(),
    );
    await _queueService.addToQueue(item);
    
    // Try to sync immediately if online
    if (_networkService.isOnline) {
      await syncQueue();
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

