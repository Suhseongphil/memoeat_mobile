import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note.dart';

class NoteActionSheet extends StatelessWidget {
  final Note note;
  final VoidCallback onMoveToFolder;
  final VoidCallback onReorder;
  final VoidCallback onDelete;

  const NoteActionSheet({
    super.key,
    required this.note,
    required this.onMoveToFolder,
    required this.onReorder,
    required this.onDelete,
  });

  static Future<void> show({
    required BuildContext context,
    required Note note,
    required VoidCallback onMoveToFolder,
    required VoidCallback onReorder,
    required VoidCallback onDelete,
  }) async {
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => NoteActionSheet(
        note: note,
        onMoveToFolder: onMoveToFolder,
        onReorder: onReorder,
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
            
            // Note title preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                note.data.title.isEmpty ? '제목 없음' : note.data.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            const Divider(),
            
            // Action buttons
            _ActionItem(
              icon: Icons.folder_outlined,
              title: '폴더로 이동',
              onTap: () {
                Navigator.pop(context);
                onMoveToFolder();
              },
            ),
            
            _ActionItem(
              icon: Icons.swap_vert,
              title: '순서 변경',
              onTap: () {
                Navigator.pop(context);
                onReorder();
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

