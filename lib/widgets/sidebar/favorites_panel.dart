import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tabs_provider.dart';
import '../../models/note.dart';
import '../note_list/note_list_item.dart';

class FavoritesPanel extends StatelessWidget {
  const FavoritesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final tabsProvider = context.watch<TabsProvider>();

    // Load favorites on build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notesProvider.loadFavoriteNotes();
    });

    final favorites = notesProvider.favoriteNotes;

    if (favorites.isEmpty) {
      return const Center(
        child: Text('즐겨찾기한 메모가 없습니다'),
      );
    }

    return ListView.builder(
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final note = favorites[index];
        return NoteListItem(
          note: note,
          onTap: () {
            tabsProvider.openNote(note);
          },
          onToggleFavorite: () {
            notesProvider.toggleFavorite(note.id);
          },
        );
      },
    );
  }
}

