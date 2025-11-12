import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/folders_provider.dart';
import '../../models/folder.dart';
import 'folder_tree_item.dart';

class FolderTree extends StatelessWidget {
  final String? selectedFolderId;
  final Function(String?) onFolderSelected;

  const FolderTree({
    super.key,
    required this.selectedFolderId,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final foldersProvider = context.watch<FoldersProvider>();

    return FutureBuilder<List<Folder>>(
      future: foldersProvider.getFolderTree(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final rootFolders = snapshot.data!;

        if (rootFolders.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: rootFolders.map((folder) {
            return FolderTreeItem(
              folder: folder,
              selectedFolderId: selectedFolderId,
              onFolderSelected: onFolderSelected,
              level: 0,
            );
          }).toList(),
        );
      },
    );
  }
}

