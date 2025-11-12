import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tabs_provider.dart';
import '../note_list/note_list_item.dart';

class MobileNoteList extends StatelessWidget {
  final String? folderId;
  final String? folderName;

  const MobileNoteList({
    super.key,
    required this.folderId,
    this.folderName,
  });

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
          child: InkWell(
            onTap: () {
              tabsProvider.openNote(note);
              // Notify parent to switch to editor view
              // This will be handled by the parent widget
            },
            child: NoteListItem(
              note: note,
              onTap: () {
                tabsProvider.openNote(note);
              },
              onToggleFavorite: () {
                notesProvider.toggleFavorite(note.id);
              },
              onLongPress: () {
                // Action sheet will be handled by parent if needed
              },
            ),
          ),
        );
      },
    );
  }
}

