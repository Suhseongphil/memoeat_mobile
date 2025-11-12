import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/tabs_provider.dart';
import '../../models/note.dart';

class MobileSearchSheet extends StatefulWidget {
  const MobileSearchSheet({super.key});

  @override
  State<MobileSearchSheet> createState() => _MobileSearchSheetState();
}

class _MobileSearchSheetState extends State<MobileSearchSheet> {
  final _searchController = TextEditingController();
  List<Note> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final notesProvider = context.read<NotesProvider>();
    final results = await notesProvider.searchNotes(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tabsProvider = context.watch<TabsProvider>();

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search input
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '메모 검색...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _performSearch,
            ),
          ),

          // Search results
          Flexible(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _searchResults.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            _searchController.text.isEmpty
                                ? '검색어를 입력하세요'
                                : '검색 결과가 없습니다',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final note = _searchResults[index];
                          return ListTile(
                            leading: Icon(
                              note.data.isFavorite
                                  ? Icons.star
                                  : Icons.note_outlined,
                              color: note.data.isFavorite
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            title: Text(note.data.title.isEmpty
                                ? '제목 없음'
                                : note.data.title),
                            subtitle: Text(
                              note.data.content.length > 50
                                  ? '${note.data.content.substring(0, 50)}...'
                                  : note.data.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              tabsProvider.openNote(note);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
          ),

          // Result count
          if (_searchResults.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Text(
                '${_searchResults.length}개 결과',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

