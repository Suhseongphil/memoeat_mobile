import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/folders_provider.dart';
import '../../providers/auth_provider.dart';
import 'mobile_folder_tree_sheet.dart';

class MobileFolderSelector extends StatelessWidget {
  final String? selectedFolderId;
  final Function(String?) onFolderSelected;

  const MobileFolderSelector({
    super.key,
    required this.selectedFolderId,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final foldersProvider = context.watch<FoldersProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final userName = user?.email?.split('@').first ?? 'Root';

    return InkWell(
      onTap: () {
        MobileFolderTreeSheet.show(
          context: context,
          selectedFolderId: selectedFolderId,
          onFolderSelected: onFolderSelected,
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selectedFolderId == null ? Icons.home : Icons.folder,
              size: 20,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                selectedFolderId == null
                    ? userName
                    : foldersProvider.folders
                            .where((f) => f.id == selectedFolderId)
                            .firstOrNull
                            ?.data
                            .name ??
                        '폴더',
                style: const TextStyle(fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

