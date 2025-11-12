import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/note.dart';
import '../../providers/notes_provider.dart';

class ReorderableNoteList extends StatefulWidget {
  final String? folderId;
  final VoidCallback onComplete;

  const ReorderableNoteList({
    super.key,
    required this.folderId,
    required this.onComplete,
  });

  @override
  State<ReorderableNoteList> createState() => _ReorderableNoteListState();
}

class _ReorderableNoteListState extends State<ReorderableNoteList> {
  List<Note> _notes = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    final notesProvider = context.read<NotesProvider>();
    _notes = notesProvider.notes
        .where((note) => note.data.folderId == widget.folderId)
        .toList()
      ..sort((a, b) => a.data.order.compareTo(b.data.order));
    setState(() {});
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final note = _notes.removeAt(oldIndex);
      _notes.insert(newIndex, note);
    });

    // Update order values immediately for visual feedback
    for (int i = 0; i < _notes.length; i++) {
      final note = _notes[i];
      final updatedNote = note.copyWith(
        data: note.data.copyWith(order: i + 1),
      );
      _notes[i] = updatedNote;
    }
    setState(() {});
  }

  Future<void> _saveOrder() async {
    if (_isSaving) return;
    
    setState(() {
      _isSaving = true;
    });

    final notesProvider = context.read<NotesProvider>();
    for (int i = 0; i < _notes.length; i++) {
      await notesProvider.updateNoteOrder(_notes[i].id, i + 1);
    }

    await notesProvider.loadNotes(folderId: widget.folderId, useCache: false);
    
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('순서 변경'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveOrder,
              child: const Text('완료'),
            ),
        ],
      ),
      body: ReorderableListView(
        padding: const EdgeInsets.all(8),
        onReorder: _onReorder,
        children: _notes.map((note) {
          return Card(
            key: ValueKey(note.id),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              leading: Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
              title: Text(
                note.data.title.isEmpty ? '제목 없음' : note.data.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                note.data.updatedAt.toString().substring(0, 16),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              trailing: note.data.isFavorite
                  ? Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }
}

