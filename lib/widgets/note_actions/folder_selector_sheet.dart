import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/folder.dart';
import '../../providers/folders_provider.dart';

class FolderSelectorSheet extends StatelessWidget {
  final String? currentFolderId;
  final Function(String?) onFolderSelected;

  const FolderSelectorSheet({
    super.key,
    required this.currentFolderId,
    required this.onFolderSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required String? currentFolderId,
    required Function(String?) onFolderSelected,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FolderSelectorSheet(
        currentFolderId: currentFolderId,
        onFolderSelected: onFolderSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final foldersProvider = context.watch<FoldersProvider>();
    final folders = foldersProvider.folders;

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
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '폴더 선택',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            const Divider(),
            
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Root folder option (null)
                  ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text('루트 폴더'),
                    trailing: currentFolderId == null
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onFolderSelected(null);
                    },
                  ),
                  
                  const Divider(),
                  
                  // Folder tree
                  ..._buildFolderList(folders, currentFolderId, context),
                ],
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFolderList(List<Folder> folders, String? currentFolderId, BuildContext context) {
    List<Widget> widgets = [];
    
    void buildTree(String? parentId, int depth) {
      final children = folders
          .where((f) => f.data.parentId == parentId)
          .toList()
        ..sort((a, b) => a.data.order.compareTo(b.data.order));
      
      for (final folder in children) {
        widgets.add(
          ListTile(
            leading: Icon(
              Icons.folder,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Padding(
              padding: EdgeInsets.only(left: depth * 24.0),
              child: Text(folder.data.name),
            ),
            trailing: currentFolderId == folder.id
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              Navigator.pop(context);
              onFolderSelected(folder.id);
            },
          ),
        );
        
        // Recursively build children
        buildTree(folder.id, depth + 1);
      }
    }
    
    buildTree(null, 0);
    return widgets;
  }
}

