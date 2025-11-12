import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notes_provider.dart';
import '../../providers/folders_provider.dart';
import '../../providers/tabs_provider.dart';
import 'explorer_panel.dart';
import 'favorites_panel.dart';
import 'search_panel.dart';
import 'trash_panel.dart';

enum SidebarPanel {
  explorer,
  favorites,
  search,
  trash,
}

class Sidebar extends StatefulWidget {
  final String? selectedFolderId;
  final Function(String?) onFolderSelected;

  const Sidebar({
    super.key,
    required this.selectedFolderId,
    required this.onFolderSelected,
  });

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  SidebarPanel _currentPanel = SidebarPanel.explorer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Panel selector
          Container(
            height: 48,
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
                _buildPanelButton(
                  icon: Icons.folder,
                  panel: SidebarPanel.explorer,
                  tooltip: '탐색기',
                ),
                _buildPanelButton(
                  icon: Icons.star,
                  panel: SidebarPanel.favorites,
                  tooltip: '즐겨찾기',
                ),
                _buildPanelButton(
                  icon: Icons.search,
                  panel: SidebarPanel.search,
                  tooltip: '검색',
                ),
                _buildPanelButton(
                  icon: Icons.delete,
                  panel: SidebarPanel.trash,
                  tooltip: '휴지통',
                ),
              ],
            ),
          ),

          // Panel content
          Expanded(
            child: _buildPanelContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelButton({
    required IconData icon,
    required SidebarPanel panel,
    required String tooltip,
  }) {
    final isSelected = _currentPanel == panel;
    return Expanded(
      child: Material(
        color: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentPanel = panel;
            });
          },
          child: Tooltip(
            message: tooltip,
            child: Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).iconTheme.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanelContent() {
    switch (_currentPanel) {
      case SidebarPanel.explorer:
        return ExplorerPanel(
          selectedFolderId: widget.selectedFolderId,
          onFolderSelected: widget.onFolderSelected,
        );
      case SidebarPanel.favorites:
        return const FavoritesPanel();
      case SidebarPanel.search:
        return const SearchPanel();
      case SidebarPanel.trash:
        return const TrashPanel();
    }
  }
}

