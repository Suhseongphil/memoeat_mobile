import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tabs_provider.dart';
import '../../providers/folders_provider.dart';
import '../note_list/note_list_item.dart';
import '../note_actions/note_action_sheet.dart';
import '../note_actions/folder_selector_sheet.dart';
import '../note_actions/reorderable_note_list.dart';
import '../../models/note.dart';

class MobileNoteListWithCallback extends StatelessWidget {
  final String? folderId;
  final VoidCallback onNoteTap;

  const MobileNoteListWithCallback({
    super.key,
    required this.folderId,
    required this.onNoteTap,
  });

  void _showActionSheet(BuildContext context, Note note) {
    NoteActionSheet.show(
      context: context,
      note: note,
      onMoveToFolder: () => _showFolderSelector(context, note),
      onReorder: () => _enterReorderMode(context),
      onDelete: () => _deleteNote(context, note),
    );
  }

  void _showFolderSelector(BuildContext context, Note note) {
    FolderSelectorSheet.show(
      context: context,
      currentFolderId: note.data.folderId,
      onFolderSelected: (folderId) async {
        final notesProvider = context.read<NotesProvider>();
        final success = await notesProvider.moveNote(note.id, folderId);
        
        if (success && context.mounted) {
          final foldersProvider = context.read<FoldersProvider>();
          String folderName = '루트 폴더';
          
          if (folderId != null) {
            try {
              final folder = foldersProvider.folders
                  .firstWhere((f) => f.id == folderId);
              folderName = folder.data.name;
            } catch (e) {
              folderName = '알 수 없는 폴더';
            }
          }
          
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('메모가 "$folderName"으로 이동되었습니다'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }

  void _enterReorderMode(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReorderableNoteList(
          folderId: folderId,
          onComplete: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _deleteNote(BuildContext context, Note note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('메모 삭제'),
        content: const Text('이 메모를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final notesProvider = context.read<NotesProvider>();
      await notesProvider.deleteNote(note.id);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('메모가 삭제되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final tabsProvider = context.watch<TabsProvider>();

    // Filter notes by folder
    final folderNotes = notesProvider.notes
        .where((note) => note.data.folderId == folderId)
        .toList();

    if (notesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (folderNotes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_outlined,
              size: 64,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(height: 16),
            Text(
              '메모가 없습니다',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '새 메모를 만들어보세요',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: folderNotes.length,
      itemBuilder: (context, index) {
        final note = folderNotes[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: NoteListItem(
            note: note,
            onTap: () {
              tabsProvider.openNote(note);
              onNoteTap();
            },
            onToggleFavorite: () {
              notesProvider.toggleFavorite(note.id);
            },
            onLongPress: () => _showActionSheet(context, note),
          ),
        );
      },
    );
  }
}

