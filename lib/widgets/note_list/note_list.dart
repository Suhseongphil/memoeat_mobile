import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../models/note.dart';
import 'note_list_item.dart';

class NoteList extends StatelessWidget {
  final String? folderId;
  final Function(Note) onNoteTap;

  const NoteList({
    super.key,
    required this.folderId,
    required this.onNoteTap,
  });

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();

    // Filter notes by folder
    final folderNotes = notesProvider.notes
        .where((note) => note.data.folderId == folderId)
        .toList();

    if (folderNotes.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('이 폴더에 메모가 없습니다'),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '메모 (${folderNotes.length})',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...folderNotes.map((note) {
          return NoteListItem(
            note: note,
            onTap: () => onNoteTap(note),
            onToggleFavorite: () {
              notesProvider.toggleFavorite(note.id);
            },
          );
        }),
      ],
    );
  }
}

