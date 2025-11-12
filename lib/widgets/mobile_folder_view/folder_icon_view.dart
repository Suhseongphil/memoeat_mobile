import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/folders_provider.dart';
import '../../models/folder.dart';

class FolderIconView extends StatelessWidget {
  final String? parentFolderId;
  final Function(String?) onFolderSelected;

  const FolderIconView({
    super.key,
    required this.parentFolderId,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final foldersProvider = context.watch<FoldersProvider>();

    return FutureBuilder<List<Folder>>(
      future: foldersProvider.getFolderTree(parentId: parentFolderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final folders = snapshot.data!;

        if (folders.isEmpty) {
          return const SizedBox.shrink();
        }

        // Calculate cross axis count based on screen width
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
          itemCount: folders.length,
          itemBuilder: (context, index) {
            final folder = folders[index];
            return _FolderIcon(
              folder: folder,
              onTap: () => onFolderSelected(folder.id),
            );
          },
        );
      },
    );
  }
}

class _FolderIcon extends StatelessWidget {
  final Folder folder;
  final VoidCallback onTap;

  const _FolderIcon({
    required this.folder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Folder icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.folder,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            // Folder name
            Flexible(
              child: Text(
                folder.data.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

