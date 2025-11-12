import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/folders_provider.dart';
import '../providers/tabs_provider.dart';
import '../widgets/editor/editor.dart';
import '../widgets/tab_bar/tab_bar.dart';
import '../widgets/editor/editor_with_back_button.dart';
import '../widgets/mobile_search/mobile_search_sheet.dart';
import '../widgets/mobile_folder_view/explorer_view.dart';
import '../services/sync_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String? _selectedFolderId;
  int _currentViewIndex = 0; // 0: 메모 목록, 1: 에디터
  late final SyncService _syncService;
  final GlobalKey<ExplorerViewState> _explorerViewKey = GlobalKey<ExplorerViewState>();

  @override
  void initState() {
    super.initState();
    // Get singleton instance
    _syncService = SyncService();
    // Start periodic sync
    _syncService.startPeriodicSync();
    
    // Load data after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _syncService.stopPeriodicSync();
    // Note: Don't dispose singleton, it's shared across the app
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    final notesProvider = context.read<NotesProvider>();
    final foldersProvider = context.read<FoldersProvider>();

    try {
      await Future.wait([
        notesProvider.loadNotes(),
        foldersProvider.loadFolders(),
      ]);
      
      // Check for errors
      if (mounted) {
        if (notesProvider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('메모 로드 오류: ${notesProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (foldersProvider.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('폴더 로드 오류: ${foldersProvider.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 로드 오류: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onFolderSelected(String? folderId) {
    setState(() {
      _selectedFolderId = folderId;
      _currentViewIndex = 0; // 메모 목록으로 전환
    });
    context.read<NotesProvider>().loadNotes(folderId: folderId);
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 1024;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final notesProvider = context.watch<NotesProvider>();
    final foldersProvider = context.watch<FoldersProvider>();
    final tabsProvider = context.watch<TabsProvider>();
    final isMobile = _isMobile(context);

    // Mobile layout
    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          leading: _currentViewIndex == 0 && _selectedFolderId != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    // Navigate to parent folder
                    final foldersProvider = context.read<FoldersProvider>();
                    final currentFolder = foldersProvider.folders
                        .where((f) => f.id == _selectedFolderId)
                        .firstOrNull;
                    final parentId = currentFolder?.data.parentId;
                    _onFolderSelected(parentId);
                  },
                )
              : null,
          actions: [
            // Search button
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => const MobileSearchSheet(),
                );
              },
            ),
            // Menu button
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'select') {
                  // Enter selection mode
                  if (_currentViewIndex == 0) {
                    _explorerViewKey.currentState?.enterSelectionMode();
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 20),
                      SizedBox(width: 8),
                      Text('선택'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentViewIndex,
          children: [
            // Explorer view (folders + notes)
            ExplorerView(
              key: _explorerViewKey,
              folderId: _selectedFolderId,
              onFolderSelected: _onFolderSelected,
              onNoteTap: () {
                setState(() {
                  _currentViewIndex = 1; // Switch to editor
                });
              },
            ),
            // Editor view
            EditorWithBackButton(
              onBack: () {
                setState(() {
                  _currentViewIndex = 0; // Switch to explorer
                });
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFF59E0B), // 노란색
          onPressed: () async {
            final note = await notesProvider.createNote(
              folderId: _selectedFolderId,
            );
            if (note != null) {
              tabsProvider.openNote(note);
              setState(() {
                _currentViewIndex = 1; // Switch to editor
              });
            }
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      );
    }

    // Desktop layout (original)
    return Scaffold(
      body: Column(
        children: [
          // Tab bar
          const TabBarWidget(),

          // Loading indicator
          if (notesProvider.isLoading || foldersProvider.isLoading)
            const LinearProgressIndicator(),

          // Editor
          const Expanded(
            child: Editor(),
          ),
        ],
      ),
    );
  }
}

