import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notes_provider.dart';
import '../../providers/folders_provider.dart';

class TrashView extends StatefulWidget {
  const TrashView({super.key});

  @override
  State<TrashView> createState() => _TrashViewState();
}

class _TrashViewState extends State<TrashView> {
  bool _hasLoaded = false;

  @override
  void initState() {
    super.initState();
    // Load deleted items once when the view is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasLoaded && mounted) {
        _hasLoaded = true;
        final notesProvider = context.read<NotesProvider>();
        final foldersProvider = context.read<FoldersProvider>();
        notesProvider.loadDeletedNotes();
        foldersProvider.loadDeletedFolders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final foldersProvider = context.watch<FoldersProvider>();

    final deletedNotes = notesProvider.deletedNotes;
    final deletedFolders = foldersProvider.deletedFolders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('휴지통'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/main'),
        ),
        actions: [
          if (deletedNotes.isNotEmpty || deletedFolders.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: '휴지통 비우기',
              onPressed: () => _showEmptyTrashDialog(
                context,
                notesProvider,
                foldersProvider,
                deletedNotes,
                deletedFolders,
              ),
            ),
        ],
      ),
      body: deletedNotes.isEmpty && deletedFolders.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('휴지통이 비어있습니다'),
              ),
            )
          : ListView(
              children: [
                // Deleted folders
                if (deletedFolders.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '삭제된 폴더',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...deletedFolders.map((folder) => _buildTrashItem(
                        context,
                        folder.data.name,
                        folder.deletedAt!,
                        Icons.folder_outlined,
                        onRestore: () async {
                          final success = await foldersProvider.restoreFolder(folder.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('폴더가 복구되었습니다'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        onDelete: () => _showPermanentDeleteDialog(
                          context,
                          '폴더',
                          folder.data.name,
                          () => foldersProvider.permanentlyDeleteFolder(folder.id),
                        ),
                      )),
                ],

                // Deleted notes
                if (deletedNotes.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      '삭제된 메모',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  ...deletedNotes.map((note) => _buildTrashItem(
                        context,
                        note.data.title.isEmpty ? '(제목 없음)' : note.data.title,
                        note.deletedAt!,
                        Icons.description_outlined,
                        onRestore: () async {
                          final success = await notesProvider.restoreNote(note.id);
                          if (success && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('메모가 복구되었습니다'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        onDelete: () => _showPermanentDeleteDialog(
                          context,
                          '메모',
                          note.data.title.isEmpty ? '(제목 없음)' : note.data.title,
                          () => notesProvider.permanentlyDeleteNote(note.id),
                        ),
                      )),
                ],
              ],
            ),
    );
  }

  Widget _buildTrashItem(
    BuildContext context,
    String title,
    DateTime deletedAt,
    IconData icon, {
    required VoidCallback onRestore,
    required VoidCallback onDelete,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[600]),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('삭제됨: ${_formatDate(deletedAt)}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              onPressed: onRestore,
              tooltip: '복구',
              color: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: onDelete,
              tooltip: '영구 삭제',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  void _showEmptyTrashDialog(
    BuildContext context,
    NotesProvider notesProvider,
    FoldersProvider foldersProvider,
    List deletedNotes,
    List deletedFolders,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('휴지통 비우기'),
        content: const Text('모든 항목을 영구 삭제하시겠습니까?'),
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

    if (confirm == true && context.mounted) {
      // Delete all notes
      for (final note in deletedNotes) {
        await notesProvider.permanentlyDeleteNote(note.id);
      }
      // Delete all folders
      for (final folder in deletedFolders) {
        await foldersProvider.permanentlyDeleteFolder(folder.id);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('휴지통이 비워졌습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _showPermanentDeleteDialog(
    BuildContext context,
    String itemType,
    String itemName,
    VoidCallback onConfirm,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('영구 삭제'),
        content: Text('이 $itemType을(를) 영구 삭제하시겠습니까?\n\n"$itemName"'),
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

    if (confirm == true) {
      onConfirm();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$itemType이(가) 영구 삭제되었습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return '방금 전';
        }
        return '${difference.inMinutes}분 전';
      }
      return '${difference.inHours}시간 전';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }
}

