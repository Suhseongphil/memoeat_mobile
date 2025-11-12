import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'dart:convert';
import 'dart:async';
import '../../providers/tabs_provider.dart';
import '../../providers/notes_provider.dart';
import '../../services/notes_service.dart';
import '../../services/network_service.dart';
import '../../services/sync_service.dart';

class Editor extends StatefulWidget {
  const Editor({super.key});

  @override
  State<Editor> createState() => _EditorState();
}

class _EditorState extends State<Editor> {
  final QuillController _controller = QuillController.basic();
  final TextEditingController _titleController = TextEditingController();
  final NotesService _notesService = NotesService();
  final NetworkService _networkService = NetworkService();
  final SyncService _syncService = SyncService();
  final FocusNode _editorFocusNode = FocusNode();
  String? _currentNoteId;
  bool _isLoading = false;
  bool _isSaving = false;
  Timer? _saveTimer;

  @override
  void initState() {
    super.initState();
    // Auto-save listeners
    _titleController.addListener(_onContentChanged);
    _controller.document.changes.listen((event) {
      _onContentChanged();
    });
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _titleController.removeListener(_onContentChanged);
    _controller.dispose();
    _titleController.dispose();
    _editorFocusNode.dispose();
    // Note: NetworkService and SyncService are singletons, don't dispose them here
    super.dispose();
  }

  void _onContentChanged() {
    if (_currentNoteId == null || _isLoading) return;

    // Cancel existing timer
    _saveTimer?.cancel();

    // Set new timer for auto-save (2초 디바운스)
    _saveTimer = Timer(const Duration(seconds: 2), () {
      _saveNote();
    });
  }

  void _loadNote(String noteId) async {
    setState(() {
      _isLoading = true;
      _currentNoteId = noteId;
    });

    // 로딩 중에는 자동 저장 방지
    _saveTimer?.cancel();

    try {
      final note = await _notesService.getNote(noteId);
      if (note != null && mounted) {
        // 리스너를 일시적으로 제거하여 로드 시 자동 저장 방지
        _titleController.removeListener(_onContentChanged);

        _titleController.text = note.data.title;

        // Content가 비어있거나 null인 경우 빈 Document로 초기화
        if (note.data.content.isEmpty) {
          _controller.document = Document()..insert(0, '\n');
        } else {
          try {
            final delta = _parseContent(note.data.content);
            _controller.document = Document.fromJson(delta);
          } catch (e) {
            // 파싱 실패 시 빈 Document로 초기화
            _controller.document = Document()..insert(0, '\n');
          }
        }

        // 리스너 다시 추가
        _titleController.addListener(_onContentChanged);

        setState(() {
          _isLoading = false;
        });

        // 새로 생성된 메모인 경우 에디터에 포커스
        if (note.data.content.isEmpty && mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _editorFocusNode.requestFocus();
          });
        }
      }
    } catch (e) {
      // 에러 발생 시에도 빈 Document로 초기화하여 입력 가능하게 함
      if (mounted) {
        _controller.document = Document()..insert(0, '\n');
        // 리스너 다시 추가
        _titleController.addListener(_onContentChanged);
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _parseContent(String content) {
    try {
      if (content.isEmpty)
        return [
          {'insert': '\n'}
        ];

      // Try to parse as JSON (Delta format)
      try {
        final decoded = json.decode(content) as List;
        return List<Map<String, dynamic>>.from(decoded);
      } catch (e) {
        // If not JSON, check if it's HTML
        if (content.trim().startsWith('<') && content.trim().endsWith('>')) {
          // Extract text from HTML
          final text = _extractTextFromHtml(content);
          return [
            {'insert': text + '\n'}
          ];
        }
        // Otherwise, treat as plain text
        return [
          {'insert': content + '\n'}
        ];
      }
    } catch (e) {
      // Fallback: return empty document
      return [
        {'insert': '\n'}
      ];
    }
  }

  String _extractTextFromHtml(String html) {
    // First, replace block-level tags with newlines to preserve structure
    String text = html
        .replaceAll(
            RegExp(r'</p>', caseSensitive: false), '\n') // Paragraph end
        .replaceAll(RegExp(r'</div>', caseSensitive: false), '\n') // Div end
        .replaceAll(
            RegExp(r'<br\s*/?>', caseSensitive: false), '\n') // Line breaks
        .replaceAll(
            RegExp(r'</li>', caseSensitive: false), '\n') // List item end
        .replaceAll(
            RegExp(r'</h[1-6]>', caseSensitive: false), '\n') // Heading end
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove all remaining HTML tags
        .replaceAll(RegExp(r'&nbsp;'), ' ') // Replace &nbsp; with space
        .replaceAll(RegExp(r'&lt;'), '<') // Replace &lt; with <
        .replaceAll(RegExp(r'&gt;'), '>') // Replace &gt; with >
        .replaceAll(RegExp(r'&amp;'), '&') // Replace &amp; with &
        .replaceAll(RegExp(r'&quot;'), '"') // Replace &quot; with "
        .replaceAll(RegExp(r'&#39;'), "'") // Replace &#39; with '
        .replaceAll(RegExp(r'&apos;'), "'"); // Replace &apos; with '

    // Normalize whitespace: replace multiple spaces/newlines with single ones
    text = text
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Multiple spaces to single space
        .replaceAll(
            RegExp(r'\n\s*\n\s*\n+'), '\n\n') // Multiple newlines to double
        .trim();

    return text;
  }

  // Auto-save function - called automatically after content changes
  Future<void> _saveNote() async {
    if (_currentNoteId == null || _isSaving) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final notesProvider = context.read<NotesProvider>();
      final note = await _notesService.getNote(_currentNoteId!);
      if (note == null) {
        setState(() {
          _isSaving = false;
        });
        return;
      }

      final content = json.encode(_controller.document.toDelta().toJson());
      final updatedData = note.data.copyWith(
        title: _titleController.text.isEmpty ? '제목 없음' : _titleController.text,
        content: content,
      );

      // Check network status
      final isOnline = await _networkService.checkConnectivity();

      if (isOnline) {
        // Online: Save directly with skipReload for instant UI update
        final success = await notesProvider.updateNote(
          _currentNoteId!,
          updatedData,
          skipReload: true,
        );

        if (success && mounted) {
          setState(() {
            _isSaving = false;
          });

          // Update tab title
          final tabsProvider = context.read<TabsProvider>();
          tabsProvider.updateTabTitle(_currentNoteId!, updatedData.title);
        } else {
          // If save failed, queue it
          await _syncService.queueUpdate(_currentNoteId!, updatedData);
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
        }
      } else {
        // Offline: Queue for later sync
        await _syncService.queueUpdate(_currentNoteId!, updatedData);

        // Update UI immediately with cached data
        await notesProvider.updateNote(
          _currentNoteId!,
          updatedData,
          skipReload: true,
        );

        if (mounted) {
          setState(() {
            _isSaving = false;
          });

          // Update tab title
          final tabsProvider = context.read<TabsProvider>();
          tabsProvider.updateTabTitle(_currentNoteId!, updatedData.title);
        }
      }
    } catch (e) {
      // On error, try to queue it
      try {
        final note = await _notesService.getNote(_currentNoteId!);
        if (note != null) {
          final content = json.encode(_controller.document.toDelta().toJson());
          final updatedData = note.data.copyWith(
            title:
                _titleController.text.isEmpty ? '제목 없음' : _titleController.text,
            content: content,
          );
          await _syncService.queueUpdate(_currentNoteId!, updatedData);

          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isSaving = false;
            });
          }
        }
      } catch (e2) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabsProvider = context.watch<TabsProvider>();
    final activeTab = tabsProvider.activeTab;

    // Load note when active tab changes
    if (activeTab != null && activeTab.noteId != _currentNoteId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadNote(activeTab.noteId);
      });
    } else if (activeTab == null && _currentNoteId != null) {
      _titleController.clear();
      _controller.clear();
      setState(() {
        _currentNoteId = null;
      });
    }

    if (activeTab == null) {
      return const Center(
        child: Text('메모를 선택하거나 새로 만드세요'),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildCustomToolbar(context),
                ),
              ),
              _buildActionButtons(context),
            ],
          ),
        ),

        // Title and content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: '제목 없음',
                    border: InputBorder.none,
                    hintStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Editor
                QuillEditor.basic(
                  controller: _controller,
                  focusNode: _editorFocusNode,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomToolbar(BuildContext context) {
    final style = _controller.getSelectionStyle();
    final isBold = style.attributes.containsKey(Attribute.bold.key);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 굵기
        IconButton(
          icon: const Icon(Icons.format_bold),
          tooltip: '굵게',
          color: isBold ? Theme.of(context).colorScheme.primary : null,
          onPressed: () {
            _controller.formatSelection(Attribute.bold);
          },
        ),

        const SizedBox(width: 4),

        // 글자 크기
        _buildFontSizeButton(context, style),

        const SizedBox(width: 4),

        // 글꼴
        _buildFontFamilyButton(context, style),

        const SizedBox(width: 4),

        // 글자 색상
        _buildTextColorButton(context, style),

        const SizedBox(width: 4),

        // 정렬
        _buildAlignmentButtons(context, style),
      ],
    );
  }

  Widget _buildFontSizeButton(BuildContext context, Style style) {
    final currentSizeAttr = style.attributes[Attribute.size.key];
    final currentSize =
        currentSizeAttr != null ? (currentSizeAttr.value as int? ?? 16) : 16;

    return PopupMenuButton<int>(
      tooltip: '글자 크기',
      icon: const Icon(Icons.format_size),
      itemBuilder: (context) => [10, 12, 14, 16, 18, 20, 24, 28, 32, 36, 48]
          .map((size) => PopupMenuItem(
                value: size,
                child: Text(
                  '$size',
                  style: TextStyle(
                    fontSize: size.toDouble(),
                    fontWeight: size == currentSize
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ))
          .toList(),
      onSelected: (size) {
        final attribute = Attribute('size', AttributeScope.inline, size);
        _controller.formatSelection(attribute);
      },
    );
  }

  Widget _buildFontFamilyButton(BuildContext context, Style style) {
    final currentFontAttr = style.attributes[Attribute.font.key];
    final currentFont =
        currentFontAttr != null ? (currentFontAttr.value as String? ?? '') : '';

    final fonts = [
      {'name': '기본', 'value': ''},
      {'name': '나눔고딕', 'value': 'NanumGothic'},
      {'name': '맑은 고딕', 'value': 'MalgunGothic'},
      {'name': '돋움', 'value': 'Dotum'},
      {'name': '굴림', 'value': 'Gulim'},
    ];

    return PopupMenuButton<String>(
      tooltip: '글꼴',
      icon: const Icon(Icons.font_download),
      itemBuilder: (context) => fonts.map((font) {
        final fontValue = font['value'] as String;
        return PopupMenuItem(
          value: fontValue,
          child: Row(
            children: [
              Text(font['name'] as String),
              if (currentFont == fontValue) ...[
                const SizedBox(width: 8),
                Icon(Icons.check,
                    size: 16, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        );
      }).toList(),
      onSelected: (font) {
        if (font.isEmpty) {
          // Remove font attribute by toggling
          final currentFont = style.attributes[Attribute.font.key];
          if (currentFont != null) {
            _controller.formatSelection(Attribute.font);
          }
        } else {
          final attribute = Attribute('font', AttributeScope.inline, font);
          _controller.formatSelection(attribute);
        }
      },
    );
  }

  Widget _buildTextColorButton(BuildContext context, Style style) {
    final currentColorAttr = style.attributes[Attribute.color.key];
    final currentColorValue =
        currentColorAttr != null ? (currentColorAttr.value as int?) : null;

    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    return PopupMenuButton<Color>(
      tooltip: '글자 색상',
      icon: const Icon(Icons.format_color_text),
      itemBuilder: (context) => colors.map((color) {
        return PopupMenuItem(
          value: color,
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
              const SizedBox(width: 8),
              if (currentColorValue == color.value)
                Icon(Icons.check,
                    size: 16, color: Theme.of(context).colorScheme.primary),
            ],
          ),
        );
      }).toList(),
      onSelected: (color) {
        final attribute =
            Attribute('color', AttributeScope.inline, color.value);
        _controller.formatSelection(attribute);
      },
    );
  }

  Widget _buildAlignmentButtons(BuildContext context, Style style) {
    final currentAlignAttr = style.attributes[Attribute.align.key];
    final currentAlign = currentAlignAttr != null
        ? (currentAlignAttr.value as String? ?? 'left')
        : 'left';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.format_align_left),
          tooltip: '왼쪽 정렬',
          color: currentAlign == 'left'
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: () {
            final attribute = Attribute('align', AttributeScope.block, 'left');
            _controller.formatSelection(attribute);
          },
        ),
        IconButton(
          icon: const Icon(Icons.format_align_center),
          tooltip: '가운데 정렬',
          color: currentAlign == 'center'
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: () {
            final attribute =
                Attribute('align', AttributeScope.block, 'center');
            _controller.formatSelection(attribute);
          },
        ),
        IconButton(
          icon: const Icon(Icons.format_align_right),
          tooltip: '오른쪽 정렬',
          color: currentAlign == 'right'
              ? Theme.of(context).colorScheme.primary
              : null,
          onPressed: () {
            final attribute = Attribute('align', AttributeScope.block, 'right');
            _controller.formatSelection(attribute);
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final notesProvider = context.watch<NotesProvider>();
    final tabsProvider = context.read<TabsProvider>();

    // 현재 메모의 즐겨찾기 상태 확인
    final currentNote = _currentNoteId != null
        ? notesProvider.notes.where((n) => n.id == _currentNoteId).firstOrNull
        : null;
    final isFavorite = currentNote?.data.isFavorite ?? false;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Save status indicator (자동 저장 중 표시)
        if (_isSaving)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),

        // Favorite button
        IconButton(
          icon: Icon(
            isFavorite ? Icons.star : Icons.star_border,
            color: isFavorite ? Colors.amber : null,
          ),
          tooltip: '즐겨찾기',
          onPressed: _currentNoteId != null
              ? () {
                  notesProvider.toggleFavorite(_currentNoteId!);
                }
              : null,
        ),

        // Delete button
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: '삭제',
          onPressed: _currentNoteId != null
              ? () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('메모 삭제'),
                      content: const Text('이 메모를 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('취소'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true && _currentNoteId != null) {
                    await notesProvider.deleteNote(_currentNoteId!);
                    tabsProvider.closeTab(tabsProvider.activeTabIndex);
                  }
                }
              : null,
        ),
      ],
    );
  }
}
