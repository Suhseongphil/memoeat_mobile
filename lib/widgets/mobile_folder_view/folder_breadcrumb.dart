import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/folders_provider.dart';
import '../../models/folder.dart';

class FolderBreadcrumb extends StatelessWidget {
  final String? currentFolderId;
  final Function(String?) onFolderSelected;

  const FolderBreadcrumb({
    super.key,
    required this.currentFolderId,
    required this.onFolderSelected,
  });

  List<_BreadcrumbItem> _buildBreadcrumbPath(
    List<Folder> allFolders,
    String? folderId,
  ) {
    final path = <_BreadcrumbItem>[];
    
    // Add root - 모바일에서는 '메인'으로 고정
    path.add(_BreadcrumbItem(
      id: null,
      name: '메인',
      isRoot: true,
    ));

    // Build path from root to current folder
    if (folderId != null) {
      String? currentId = folderId;
      final folderMap = {for (var f in allFolders) f.id: f};
      final pathFolders = <Folder>[];

      // Traverse up the folder tree
      while (currentId != null) {
        final folder = folderMap[currentId];
        if (folder != null) {
          pathFolders.insert(0, folder);
          currentId = folder.data.parentId;
        } else {
          break;
        }
      }

      // Add folders to path
      for (final folder in pathFolders) {
        path.add(_BreadcrumbItem(
          id: folder.id,
          name: folder.data.name,
          isRoot: false,
        ));
      }
    }

    return path;
  }

  @override
  Widget build(BuildContext context) {
    final foldersProvider = context.watch<FoldersProvider>();

    final path = _buildBreadcrumbPath(
      foldersProvider.folders,
      currentFolderId,
    );

    // 루트일 때도 항상 표시
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...path.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == path.length - 1;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkWell(
                    onTap: isLast
                        ? null
                        : () => onFolderSelected(item.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: item.isRoot
                          ? Icon(
                              Icons.folder,
                              size: 20,
                              color: isLast
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurface,
                            )
                          : Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
                                color: isLast
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                  if (!isLast)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _BreadcrumbItem {
  final String? id;
  final String name;
  final bool isRoot;

  _BreadcrumbItem({
    required this.id,
    required this.name,
    required this.isRoot,
  });
}

