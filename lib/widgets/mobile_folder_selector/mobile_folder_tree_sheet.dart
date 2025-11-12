import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/folders_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/folder.dart';

class MobileFolderTreeSheet extends StatelessWidget {
  final String? selectedFolderId;
  final Function(String?) onFolderSelected;

  const MobileFolderTreeSheet({
    super.key,
    required this.selectedFolderId,
    required this.onFolderSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String? selectedFolderId,
    required Function(String?) onFolderSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => MobileFolderTreeSheet(
        selectedFolderId: selectedFolderId,
        onFolderSelected: onFolderSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foldersProvider = context.watch<FoldersProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final userName = user?.email?.split('@').first ?? 'Root';

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Text(
                    '폴더',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.create_new_folder),
                    tooltip: '새 폴더',
                    onPressed: () async {
                      final name = await _showCreateFolderDialog(context);
                      if (name != null && name.isNotEmpty) {
                        await foldersProvider.createFolder(
                          name: name,
                          parentId: selectedFolderId,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),

            const Divider(),

            // Folder tree
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Root folder (user name)
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                        onFolderSelected(null);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selectedFolderId == null
                              ? Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withOpacity(0.3)
                              : null,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.home, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                userName,
                                style: TextStyle(
                                  fontWeight: selectedFolderId == null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (selectedFolderId == null)
                              Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Folder tree
                    FutureBuilder<List<Folder>>(
                      future: foldersProvider.getFolderTree(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final rootFolders = snapshot.data!;

                        if (rootFolders.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                '폴더가 없습니다',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color,
                                    ),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: rootFolders.map((folder) {
                            return _MobileFolderTreeItem(
                              folder: folder,
                              selectedFolderId: selectedFolderId,
                              onFolderSelected: (folderId) {
                                Navigator.pop(context);
                                onFolderSelected(folderId);
                              },
                              level: 0,
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Future<String?> _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 폴더'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '폴더 이름',
            hintText: '폴더 이름을 입력하세요',
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
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }
}

class _MobileFolderTreeItem extends StatefulWidget {
  final Folder folder;
  final String? selectedFolderId;
  final Function(String?) onFolderSelected;
  final int level;

  const _MobileFolderTreeItem({
    required this.folder,
    required this.selectedFolderId,
    required this.onFolderSelected,
    this.level = 0,
  });

  @override
  State<_MobileFolderTreeItem> createState() => _MobileFolderTreeItemState();
}

class _MobileFolderTreeItemState extends State<_MobileFolderTreeItem> {
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
          child: Container(
            padding: EdgeInsets.only(
              left: 16.0 + (widget.level * 24.0),
              right: 16.0,
              top: 12.0,
              bottom: 12.0,
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
                      size: 24,
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
                  const SizedBox(width: 40),
                Icon(
                  Icons.folder,
                  size: 24,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.folder.data.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
        if (_isExpanded && hasChildren)
          ..._children!.map((child) {
            return _MobileFolderTreeItem(
              folder: child,
              selectedFolderId: widget.selectedFolderId,
              onFolderSelected: widget.onFolderSelected,
              level: widget.level + 1,
            );
          }),
      ],
    );
  }
}

