import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/folder.dart';

class FolderActionSheet extends StatelessWidget {
  final Folder folder;
  final VoidCallback onRename;
  final VoidCallback onMove;
  final VoidCallback onDelete;

  const FolderActionSheet({
    super.key,
    required this.folder,
    required this.onRename,
    required this.onMove,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required Folder folder,
    required VoidCallback onRename,
    required VoidCallback onMove,
    required VoidCallback onDelete,
  }) async {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FolderActionSheet(
        folder: folder,
        onRename: onRename,
        onMove: onMove,
        onDelete: onDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            
            // Folder name preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                folder.data.name.isEmpty ? '이름 없음' : folder.data.name,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const Divider(),
            
            // Action buttons
            _ActionItem(
              icon: Icons.edit,
              title: '이름 변경',
              onTap: () {
                Navigator.pop(context);
                onRename();
              },
            ),
            
            _ActionItem(
              icon: Icons.folder_outlined,
              title: '폴더로 이동',
              onTap: () {
                Navigator.pop(context);
                onMove();
              },
            ),
            
            _ActionItem(
              icon: Icons.delete_outline,
              title: '삭제',
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
              isDestructive: true,
            ),
            
            const SizedBox(height: 8),
            
            // Cancel button
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.onSurface,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      ),
      onTap: onTap,
    );
  }
}

