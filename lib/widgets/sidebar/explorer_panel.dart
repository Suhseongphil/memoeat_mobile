import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/folders_provider.dart';
import '../../providers/tabs_provider.dart';
import '../../models/note.dart';
import '../../models/folder.dart';
import '../folder_tree/folder_tree.dart';
import '../note_list/note_list.dart';

class ExplorerPanel extends StatelessWidget {
  final String? selectedFolderId;
  final Function(String?) onFolderSelected;

  const ExplorerPanel({
    super.key,
    required this.selectedFolderId,
    required this.onFolderSelected,
  });

  @override
  Widget build(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final foldersProvider = context.watch<FoldersProvider>();
    final tabsProvider = context.watch<TabsProvider>();

    return Column(
      children: [
        // Header with buttons
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
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final note = await notesProvider.createNote(
                      folderId: selectedFolderId,
                    );
                    if (note != null) {
                      tabsProvider.openNote(note);
                    }
                  },
                  icon: const Icon(Icons.note_add, size: 18),
                  label: const Text('새 메모'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () async {
                  final name = await _showCreateFolderDialog(context);
                  if (name != null && name.isNotEmpty) {
                    await foldersProvider.createFolder(
                      name: name,
                      parentId: selectedFolderId,
                    );
                  }
                },
                icon: const Icon(Icons.create_new_folder, size: 20),
                tooltip: '새 폴더',
              ),
            ],
          ),
        ),

        // Folder tree and note list
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Root folder (user name)
                _buildRootFolder(context, notesProvider, tabsProvider),

                // Folder tree
                FolderTree(
                  selectedFolderId: selectedFolderId,
                  onFolderSelected: onFolderSelected,
                ),

                // Note list for selected folder (including root)
                NoteList(
                  folderId: selectedFolderId,
                  onNoteTap: (note) {
                    tabsProvider.openNote(note);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRootFolder(
    BuildContext context,
    NotesProvider notesProvider,
    TabsProvider tabsProvider,
  ) {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    final userName = user?.email?.split('@').first ?? 'Root';

    return InkWell(
      onTap: () {
        onFolderSelected(null);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selectedFolderId == null
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : null,
        ),
        child: Row(
          children: [
            const Icon(Icons.home, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showCreateFolderDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('새 폴더'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '폴더 이름',
            hintText: '폴더 이름을 입력하세요',
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(controller.text);
            },
            child: const Text('생성'),
          ),
        ],
      ),
    );
  }
}

