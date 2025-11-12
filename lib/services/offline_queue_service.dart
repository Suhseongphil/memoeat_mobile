import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineQueueItem {
  final String id;
  final String type; // 'update', 'create', 'delete'
  final String noteId;
  final Map<String, dynamic>? data;
  final DateTime timestamp;
  final int retryCount;

  OfflineQueueItem({
    required this.id,
    required this.type,
    required this.noteId,
    this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'noteId': noteId,
        'data': data,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) =>
      OfflineQueueItem(
        id: json['id'] as String,
        type: json['type'] as String,
        noteId: json['noteId'] as String,
        data: json['data'] as Map<String, dynamic>?,
        timestamp: DateTime.parse(json['timestamp'] as String),
        retryCount: json['retryCount'] as int? ?? 0,
      );
}

class OfflineQueueService {
  static const String _queueKey = 'offline_save_queue';

  // Add item to queue
  Future<void> addToQueue(OfflineQueueItem item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      List<Map<String, dynamic>> queue = [];

      if (queueJson != null) {
        queue = List<Map<String, dynamic>>.from(json.decode(queueJson));
      }

      // Remove existing item with same noteId and type
      queue.removeWhere((q) =>
          q['noteId'] == item.noteId && q['type'] == item.type);

      queue.add(item.toJson());
      await prefs.setString(_queueKey, json.encode(queue));
    } catch (e) {
      // Ignore errors
    }
  }

  // Get all items from queue
  Future<List<OfflineQueueItem>> getQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      if (queueJson == null) return [];

      final queue = List<Map<String, dynamic>>.from(json.decode(queueJson));
      return queue
          .map((item) => OfflineQueueItem.fromJson(item))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Remove item from queue
  Future<void> removeFromQueue(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      if (queueJson == null) return;

      final queue = List<Map<String, dynamic>>.from(json.decode(queueJson));
      queue.removeWhere((item) => item['id'] == itemId);

      await prefs.setString(_queueKey, json.encode(queue));
    } catch (e) {
      // Ignore errors
    }
  }

  // Clear queue
  Future<void> clearQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_queueKey);
    } catch (e) {
      // Ignore errors
    }
  }

  // Update retry count
  Future<void> incrementRetryCount(String itemId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueJson = prefs.getString(_queueKey);
      if (queueJson == null) return;

      final queue = List<Map<String, dynamic>>.from(json.decode(queueJson));
      final index = queue.indexWhere((item) => item['id'] == itemId);
      if (index >= 0) {
        queue[index]['retryCount'] =
            (queue[index]['retryCount'] as int? ?? 0) + 1;
        await prefs.setString(_queueKey, json.encode(queue));
      }
    } catch (e) {
      // Ignore errors
    }
  }
}

