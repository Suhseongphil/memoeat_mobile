import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/folders_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tabs_provider.dart';
import '../../models/folder.dart';
import '../../models/note.dart';
import '../note_actions/folder_selector_sheet.dart';
import 'folder_breadcrumb.dart';

enum ViewMode { icons, list }

enum _ItemType { folder, note }

class _ExplorerItem {
  final _ItemType type;
  final Folder? folder;
  final Note? note;
  final int order;

  _ExplorerItem({
    required this.type,
    this.folder,
    this.note,
    required this.order,
  });
}

class ExplorerView extends StatefulWidget {
  final String? folderId;
  final Function(String?) onFolderSelected;
  final VoidCallback onNoteTap;

  const ExplorerView({
    super.key,
    required this.folderId,
    required this.onFolderSelected,
    required this.onNoteTap,
  });

  @override
  State<ExplorerView> createState() => _ExplorerViewState();

  // Public state class for GlobalKey access
  static State<ExplorerView> createStatePublic() => _ExplorerViewState();
}

// Public state class for GlobalKey
abstract class ExplorerViewState extends State<ExplorerView> {
  void enterSelectionMode();
}

class _ExplorerViewState extends ExplorerViewState {
  ViewMode _viewMode = ViewMode.icons;
  bool _isSelectionMode = false;
  final Set<String> _selectedItems =
      {}; // Store IDs of selected items (folders and notes)

  @override
  void enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedItems.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedItems.clear();
    });
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedItems.contains(itemId)) {
        _selectedItems.remove(itemId);
      } else {
        _selectedItems.add(itemId);
      }
    });
  }

  bool _isSelected(String itemId) {
    return _selectedItems.contains(itemId);
  }

  Future<void> _handleMove() async {
    if (_selectedItems.isEmpty) return;

    final foldersProvider = context.read<FoldersProvider>();
    final notesProvider = context.read<NotesProvider>();

    await FolderSelectorSheet.show(
      context: context,
      currentFolderId: widget.folderId,
      onFolderSelected: (targetFolderId) async {
        for (final itemId in _selectedItems) {
          // Check if it's a folder or note
          final folder =
              foldersProvider.folders.where((f) => f.id == itemId).firstOrNull;
          if (folder != null) {
            await foldersProvider.moveFolder(itemId, targetFolderId);
          } else {
            await notesProvider.moveNote(itemId, targetFolderId);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이동되었습니다')),
          );
          _exitSelectionMode();
        }
      },
    );
  }

  Future<void> _handleDelete() async {
    if (_selectedItems.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('${_selectedItems.length}개의 항목을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final foldersProvider = context.read<FoldersProvider>();
      final notesProvider = context.read<NotesProvider>();

      for (final itemId in _selectedItems) {
        // Check if it's a folder or note
        final folder =
            foldersProvider.folders.where((f) => f.id == itemId).firstOrNull;
        if (folder != null) {
          await foldersProvider.deleteFolder(itemId);
        } else {
          await notesProvider.deleteNote(itemId);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('삭제되었습니다')),
        );
        _exitSelectionMode();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final foldersProvider = context.watch<FoldersProvider>();
    final notesProvider = context.watch<NotesProvider>();
    final tabsProvider = context.watch<TabsProvider>();

    // Get subfolders and notes for current folder
    final subfolders = foldersProvider.folders
        .where((f) => f.data.parentId == widget.folderId)
        .toList()
      ..sort((a, b) => a.data.order.compareTo(b.data.order));

    final notes = notesProvider.notes
        .where((note) => note.data.folderId == widget.folderId)
        .toList()
      ..sort((a, b) => a.data.order.compareTo(b.data.order));

    if (notesProvider.isLoading) {
      return Column(
        children: [
          _buildToolbar(),
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      );
    }

    final hasContent = subfolders.isNotEmpty || notes.isNotEmpty;

    return Column(
      children: [
        _buildToolbar(),
        Expanded(
          child: hasContent
              ? (_viewMode == ViewMode.icons
                  ? _buildIconView(subfolders, notes, tabsProvider)
                  : _buildListView(subfolders, notes, tabsProvider))
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 64,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '비어있습니다',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '새 폴더나 메모를 만들어보세요',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
        ),
        // Bottom action bar when in selection mode
        if (_isSelectionMode && _selectedItems.isNotEmpty)
          _buildBottomActionBar(),
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Selection mode indicator
          if (_isSelectionMode)
            Expanded(
              child: Text(
                '${_selectedItems.length}개 선택됨',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            )
          else
            // Folder breadcrumb navigator
            FolderBreadcrumb(
              currentFolderId: widget.folderId,
              onFolderSelected: widget.onFolderSelected,
            ),
          // View mode toggle buttons (hidden in selection mode)
          if (!_isSelectionMode)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.view_module,
                    color: _viewMode == ViewMode.icons
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: '아이콘 뷰',
                  onPressed: () {
                    setState(() {
                      _viewMode = ViewMode.icons;
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.view_list,
                    color: _viewMode == ViewMode.list
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  tooltip: '리스트 뷰',
                  onPressed: () {
                    setState(() {
                      _viewMode = ViewMode.list;
                    });
                  },
                ),
              ],
            ),
          // Cancel button in selection mode
          if (_isSelectionMode)
            TextButton(
              onPressed: _exitSelectionMode,
              child: const Text('취소'),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.drive_file_move,
              label: '이동',
              onPressed: _handleMove,
            ),
            _buildActionButton(
              icon: Icons.delete,
              label: '삭제',
              onPressed: _handleDelete,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Theme.of(context).colorScheme.onSurface),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color ?? Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconView(
    List<Folder> subfolders,
    List<Note> notes,
    TabsProvider tabsProvider,
  ) {
    final List<_ExplorerItem> items = [
      ...subfolders.map((f) => _ExplorerItem(
            type: _ItemType.folder,
            folder: f,
            order: f.data.order,
          )),
      ...notes.map((n) => _ExplorerItem(
            type: _ItemType.note,
            note: n,
            order: n.data.order,
          )),
    ]..sort((a, b) => a.order.compareTo(b.order));

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 120).floor().clamp(2, 4);

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item.type == _ItemType.folder) {
          return _FolderIcon(
            folder: item.folder!,
            isSelectionMode: _isSelectionMode,
            isSelected: _isSelectionMode && _isSelected(item.folder!.id),
            onTap: _isSelectionMode
                ? () => _toggleSelection(item.folder!.id)
                : () => widget.onFolderSelected(item.folder!.id),
          );
        } else {
          return _NoteIcon(
            note: item.note!,
            isSelectionMode: _isSelectionMode,
            isSelected: _isSelectionMode && _isSelected(item.note!.id),
            onTap: _isSelectionMode
                ? () => _toggleSelection(item.note!.id)
                : () {
                    tabsProvider.openNote(item.note!);
                    widget.onNoteTap();
                  },
          );
        }
      },
    );
  }

  Widget _buildListView(
    List<Folder> subfolders,
    List<Note> notes,
    TabsProvider tabsProvider,
  ) {
    final List<_ExplorerItem> items = [
      ...subfolders.map((f) => _ExplorerItem(
            type: _ItemType.folder,
            folder: f,
            order: f.data.order,
          )),
      ...notes.map((n) => _ExplorerItem(
            type: _ItemType.note,
            note: n,
            order: n.data.order,
          )),
    ]..sort((a, b) => a.order.compareTo(b.order));

    return ListView(
      padding: const EdgeInsets.all(8),
      children: items.map((item) {
        if (item.type == _ItemType.folder) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: _isSelectionMode
                  ? null
                  : Icon(
                      Icons.folder,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              title: Text(item.folder!.data.name),
              trailing: _isSelectionMode
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _isSelected(item.folder!.id)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSelected(item.folder!.id)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: _isSelected(item.folder!.id)
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    )
                  : null,
              onTap: _isSelectionMode
                  ? () => _toggleSelection(item.folder!.id)
                  : () => widget.onFolderSelected(item.folder!.id),
            ),
          );
        } else {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: null,
              title: Text(item.note!.data.title.isEmpty
                  ? '제목 없음'
                  : item.note!.data.title),
              trailing: _isSelectionMode
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _isSelected(item.note!.id)
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isSelected(item.note!.id)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: _isSelected(item.note!.id)
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    )
                  : (item.note!.data.isFavorite
                      ? IconButton(
                          icon: const Icon(
                            Icons.star,
                            color: Colors.amber,
                          ),
                          onPressed: () {
                            context
                                .read<NotesProvider>()
                                .toggleFavorite(item.note!.id);
                          },
                        )
                      : null),
              onTap: _isSelectionMode
                  ? () => _toggleSelection(item.note!.id)
                  : () {
                      tabsProvider.openNote(item.note!);
                      widget.onNoteTap();
                    },
            ),
          );
        }
      }).toList(),
    );
  }
}

class _FolderIcon extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;
  final bool isSelectionMode;
  final bool isSelected;

  const _FolderIcon({
    required this.folder,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: 2, // 항상 동일한 두께로 유지하여 레이아웃 이동 방지
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none, // 체크박스가 컨테이너 밖으로 나가도 잘리지 않도록
          children: [
            // 아이콘과 텍스트를 정확히 가운데 정렬
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    folder.data.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            // Selection checkbox - always show in selection mode
            if (isSelectionMode)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteIcon extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final bool isSelectionMode;
  final bool isSelected;

  const _NoteIcon({
    required this.note,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.only(
          top: 16,
          bottom: 12,
          left: 12,
          right: 12,
        ), // 상단 패딩을 늘려 별이 잘리지 않도록
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).dividerColor,
            width: 2, // 항상 동일한 두께로 유지하여 레이아웃 이동 방지
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none, // 체크박스가 컨테이너 밖으로 나가도 잘리지 않도록
          children: [
            // 아이콘과 텍스트를 정확히 가운데 정렬
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none, // 별이 잘리지 않도록
                      children: [
                        // 메모 아이콘 - 모든 메모에 동일하게 표시
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                        ),
                        // 즐겨찾기 별 - 좌측 상단에 배치 (항상 노란색)
                        if (note.data.isFavorite)
                          Positioned(
                            top: -6,
                            left: -4,
                            child: Icon(
                              Icons.star,
                              size: 28,
                              color: Colors.amber,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    note.data.title.isEmpty ? '제목 없음' : note.data.title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
            ),
            // Selection checkbox - always show in selection mode
            if (isSelectionMode)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        )
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
