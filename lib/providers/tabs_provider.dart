import 'package:flutter/foundation.dart';
import '../models/note.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'dart:convert';

class TabItem {
  final String noteId;
  final String title;
  final DateTime openedAt;

  TabItem({
    required this.noteId,
    required this.title,
    required this.openedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'noteId': noteId,
      'title': title,
      'openedAt': openedAt.toIso8601String(),
    };
  }

  factory TabItem.fromJson(Map<String, dynamic> json) {
    return TabItem(
      noteId: json['noteId'] as String,
      title: json['title'] as String,
      openedAt: DateTime.parse(json['openedAt'] as String),
    );
  }
}

class TabsProvider with ChangeNotifier {
  final List<TabItem> _tabs = [];
  int _activeTabIndex = -1;

  List<TabItem> get tabs => _tabs;
  int get activeTabIndex => _activeTabIndex;
  TabItem? get activeTab => _activeTabIndex >= 0 && _activeTabIndex < _tabs.length
      ? _tabs[_activeTabIndex]
      : null;

  bool _isInitialized = false;

  TabsProvider() {
    // Delay initialization to ensure native channels are ready
    Future.microtask(() => _loadTabs());
  }

  // Load tabs from storage
  Future<void> _loadTabs() async {
    if (_isInitialized) return;
    
    try {
      // Add delay to ensure native channels are ready
      await Future.delayed(const Duration(milliseconds: 500));
      
      SharedPreferences? prefs;
      try {
        prefs = await SharedPreferences.getInstance();
      } catch (e) {
        // SharedPreferences not ready yet, mark as initialized with empty tabs
        _isInitialized = true;
        return;
      }
      
      final tabsJson = prefs.getString(AppConstants.tabsKey);
      if (tabsJson != null) {
        final List<dynamic> tabsList = json.decode(tabsJson);
        _tabs.clear();
        _tabs.addAll(
          tabsList.map((json) => TabItem.fromJson(json as Map<String, dynamic>)),
        );
        if (_tabs.isNotEmpty) {
          _activeTabIndex = 0;
        }
        notifyListeners();
      }
      _isInitialized = true;
    } catch (e) {
      // Ignore errors, mark as initialized with empty tabs
      _isInitialized = true;
      debugPrint('Error loading tabs: $e');
    }
  }

  // Save tabs to storage
  Future<void> _saveTabs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tabsJson = json.encode(_tabs.map((tab) => tab.toJson()).toList());
      await prefs.setString(AppConstants.tabsKey, tabsJson);
    } catch (e) {
      // Ignore errors
    }
  }

  // Open note in new tab
  void openNote(Note note) {
    // Check if note is already open
    final existingIndex = _tabs.indexWhere((tab) => tab.noteId == note.id);
    if (existingIndex >= 0) {
      _activeTabIndex = existingIndex;
      notifyListeners();
      return;
    }

    // Add new tab
    _tabs.add(TabItem(
      noteId: note.id,
      title: note.data.title,
      openedAt: DateTime.now(),
    ));
    _activeTabIndex = _tabs.length - 1;
    _saveTabs();
    notifyListeners();
  }

  // Close tab
  void closeTab(int index) {
    if (index < 0 || index >= _tabs.length) return;

    _tabs.removeAt(index);

    // Adjust active tab index
    if (_tabs.isEmpty) {
      _activeTabIndex = -1;
    } else if (_activeTabIndex >= _tabs.length) {
      _activeTabIndex = _tabs.length - 1;
    } else if (_activeTabIndex > index) {
      _activeTabIndex--;
    }

    _saveTabs();
    notifyListeners();
  }

  // Set active tab
  void setActiveTab(int index) {
    if (index >= 0 && index < _tabs.length) {
      _activeTabIndex = index;
      notifyListeners();
    }
  }

  // Switch to next tab
  void nextTab() {
    if (_tabs.isEmpty) return;
    _activeTabIndex = (_activeTabIndex + 1) % _tabs.length;
    notifyListeners();
  }

  // Switch to previous tab
  void previousTab() {
    if (_tabs.isEmpty) return;
    _activeTabIndex = (_activeTabIndex - 1 + _tabs.length) % _tabs.length;
    notifyListeners();
  }

  // Update tab title
  void updateTabTitle(String noteId, String newTitle) {
    final index = _tabs.indexWhere((tab) => tab.noteId == noteId);
    if (index >= 0) {
      _tabs[index] = TabItem(
        noteId: _tabs[index].noteId,
        title: newTitle,
        openedAt: _tabs[index].openedAt,
      );
      _saveTabs();
      notifyListeners();
    }
  }

  // Close all tabs
  void closeAllTabs() {
    _tabs.clear();
    _activeTabIndex = -1;
    _saveTabs();
    notifyListeners();
  }
}

