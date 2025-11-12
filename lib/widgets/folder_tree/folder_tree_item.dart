import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/folders_provider.dart';
import '../../models/folder.dart';

class FolderTreeItem extends StatefulWidget {
  final Folder folder;
  final String? selectedFolderId;
  final Function(String?) onFolderSelected;
  final int level;

  const FolderTreeItem({
    super.key,
    required this.folder,
    required this.selectedFolderId,
    required this.onFolderSelected,
    this.level = 0,
  });

  @override
  State<FolderTreeItem> createState() => _FolderTreeItemState();
}

class _FolderTreeItemState extends State<FolderTreeItem> {
  bool _isExpanded = false;
  List<Folder>? _children;

  @override
  void initState() {
    super.initState();
    _loadChildren();
  }

  Future<void> _loadChildren() async {
    final foldersProvider = context.read<FoldersProvider>();
    final children = await foldersProvider.getFolderTree(
      parentId: widget.folder.id,
    );
    setState(() {
      _children = children;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.selectedFolderId == widget.folder.id;
    final hasChildren = _children != null && _children!.isNotEmpty;

    return Column(
      children: [
        InkWell(
          onTap: () {
            widget.onFolderSelected(widget.folder.id);
          },
          onLongPress: () async {
            final action = await _showFolderMenu(context);
            if (action != null) {
              _handleFolderAction(action);
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + (widget.level * 24.0),
              right: 16.0,
              top: 8.0,
              bottom: 8.0,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3)
                  : null,
            ),
            child: Row(
              children: [
                if (hasChildren)
                  IconButton(
                    icon: Icon(
                      _isExpanded ? Icons.expand_more : Icons.chevron_right,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  )
                else
                  const SizedBox(width: 32),
                const Icon(Icons.folder, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.folder.data.name,
                    style: TextStyle(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded && hasChildren)
          ..._children!.map((child) {
            return FolderTreeItem(
              folder: child,
              selectedFolderId: widget.selectedFolderId,
              onFolderSelected: widget.onFolderSelected,
              level: widget.level + 1,
            );
          }),
      ],
    );
  }

  Future<String?> _showFolderMenu(BuildContext context) async {
    return showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('이름 변경'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('삭제', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleFolderAction(String action) async {
    final foldersProvider = context.read<FoldersProvider>();

    switch (action) {
      case 'rename':
        final newName = await _showRenameDialog();
        if (newName != null && newName.isNotEmpty) {
          final updatedData = widget.folder.data.copyWith(name: newName);
          await foldersProvider.updateFolder(widget.folder.id, updatedData);
        }
        break;
      case 'delete':
        final confirm = await _showDeleteConfirmDialog();
        if (confirm == true) {
          await foldersProvider.deleteFolder(widget.folder.id);
        }
        break;
    }
  }

  Future<String?> _showRenameDialog() async {
    final controller = TextEditingController(text: widget.folder.data.name);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 이름 변경'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '폴더 이름',
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
            child: const Text('변경'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('폴더 삭제'),
        content: const Text('이 폴더와 하위 폴더, 메모가 모두 삭제됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}
