import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/note.dart';
import 'package:intl/intl.dart';

class NoteListItem extends StatefulWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onLongPress;

  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
    this.onToggleFavorite,
    this.onLongPress,
  });

  @override
  State<NoteListItem> createState() => _NoteListItemState();
}

class _NoteListItemState extends State<NoteListItem>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPressed = true;
    });
    _animationController.forward();
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
        _animationController.reverse();
        widget.onLongPress?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final updatedAt = dateFormat.format(widget.note.data.updatedAt);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: ListTile(
        leading: Icon(
          widget.note.data.isFavorite ? Icons.star : Icons.note_outlined,
          color: widget.note.data.isFavorite
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
        title: Text(
          widget.note.data.title.isEmpty ? '제목 없음' : widget.note.data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          updatedAt,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress != null ? _handleLongPress : null,
        trailing: widget.note.data.isFavorite
            ? IconButton(
                icon: const Icon(Icons.star),
                color: Theme.of(context).colorScheme.primary,
                onPressed: widget.onToggleFavorite,
              )
            : null,
        tileColor: _isPressed
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : null,
      ),
    );
  }
}

