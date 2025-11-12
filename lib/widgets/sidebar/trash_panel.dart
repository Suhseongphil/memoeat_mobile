import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/folders_provider.dart';
import '../../models/note.dart';
import '../../models/folder.dart';

class TrashPanel extends StatelessWidget {
  const TrashPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final foldersProvider = context.watch<FoldersProvider>();

    // Load deleted items on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notesProvider.loadDeletedNotes();
      foldersProvider.loadDeletedFolders();
    });

    final deletedNotes = notesProvider.deletedNotes;
    final deletedFolders = foldersProvider.deletedFolders;

    return Column(
      children: [
        // Header with empty trash button
        Container(
          padding: const EdgeInsets.all(8),
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
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
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

                    if (confirm == true) {
                      // Delete all notes
                      for (final note in deletedNotes) {
                        await notesProvider.permanentlyDeleteNote(note.id);
                      }
                      // Delete all folders
                      for (final folder in deletedFolders) {
                        await foldersProvider.permanentlyDeleteFolder(folder.id);
                      }
                    }
                  },
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('휴지통 비우기'),
                ),
              ),
            ],
          ),
        ),

        // Deleted items list
        Expanded(
          child: ListView(
            children: [
              // Deleted folders
              if (deletedFolders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '삭제된 폴더',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ...deletedFolders.map((folder) => _buildTrashItem(
                      context,
                      folder.data.name,
                      folder.deletedAt!,
                      onRestore: () {
                        foldersProvider.restoreFolder(folder.id);
                      },
                      onDelete: () {
                        foldersProvider.permanentlyDeleteFolder(folder.id);
                      },
                    )),
              ],

              // Deleted notes
              if (deletedNotes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '삭제된 메모',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ...deletedNotes.map((note) => _buildTrashItem(
                      context,
                      note.data.title,
                      note.deletedAt!,
                      onRestore: () {
                        notesProvider.restoreNote(note.id);
                      },
                      onDelete: () {
                        notesProvider.permanentlyDeleteNote(note.id);
                      },
                    )),
              ],

              if (deletedNotes.isEmpty && deletedFolders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('휴지통이 비어있습니다'),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrashItem(
    BuildContext context,
    String title,
    DateTime deletedAt, {
    required VoidCallback onRestore,
    required VoidCallback onDelete,
  }) {
    return ListTile(
      leading: const Icon(Icons.delete_outline),
      title: Text(title),
      subtitle: Text('삭제됨: ${_formatDate(deletedAt)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.restore),
            onPressed: onRestore,
            tooltip: '복구',
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('영구 삭제'),
                  content: const Text('이 항목을 영구 삭제하시겠습니까?'),
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
                onDelete();
              }
            },
            tooltip: '영구 삭제',
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '오늘';
    } else if (difference.inDays == 1) {
      return '어제';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${date.year}-${date.month}-${date.day}';
    }
  }
}

