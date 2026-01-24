import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/diary_entry.dart';
import '../services/ai_assistant_service.dart';
import 'home_page.dart';

final aiServiceProvider = Provider<AiAssistantService>(
  (ref) => MockAiAssistantService(),
);

class EditorPage extends ConsumerStatefulWidget {
  final String entryId;
  final bool isNew;
  const EditorPage({super.key, required this.entryId, this.isNew = false});

  @override
  ConsumerState<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends ConsumerState<EditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _content;
  DiaryEntry? _entry;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final box = ref.read(entriesBoxProvider);
    _entry = box.get(widget.entryId);
    _title = TextEditingController(text: _entry?.title ?? '');
    _content = TextEditingController(text: _entry?.content ?? '');
  }

  Future<void> _save() async {
    final box = ref.read(entriesBoxProvider);
    final updated = DiaryEntry(
      id: widget.entryId,
      title: _title.text,
      content: _content.text,
      createdAt: _entry?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      tags: _entry?.tags ?? const [],
    );
    await box.put(widget.entryId, updated);
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('保存しました')));
  }

  Future<void> _suggest() async {
    setState(() => _loading = true);
    try {
      final ai = ref.read(aiServiceProvider);
      final hint = await ai.suggest(_title.text, _content.text);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (_) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI ヒント',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(hint),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる'),
                  ),
                  FilledButton(
                    onPressed: () {
                      _content.text = ('${_content.text}\n\n$hint').trim();
                      Navigator.pop(context);
                    },
                    child: const Text('本文に挿入'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNew ? '新規作成' : '編集'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _suggest,
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(onPressed: _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _content,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  labelText: '本文',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
