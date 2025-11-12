import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'editor.dart';
import '../../providers/tabs_provider.dart';

class EditorWithBackButton extends StatelessWidget {
  final VoidCallback onBack;

  const EditorWithBackButton({
    super.key,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final tabsProvider = context.watch<TabsProvider>();
    
    return Stack(
      children: [
        const Editor(),
        if (tabsProvider.activeTab != null)
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: Material(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: onBack,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(Icons.arrow_back),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

