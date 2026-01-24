import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/diary_entry.dart';
import 'editor_page.dart';

final entriesBoxProvider = Provider<Box<DiaryEntry>>(
  (ref) => throw UnimplementedError(),
);
final entriesProvider = StateProvider<List<DiaryEntry>>((ref) {
  final box = ref.watch(entriesBoxProvider);
  return box.values.toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(entriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('AI Diary')),
      body: entries.isEmpty
          ? const Center(child: Text('まだ日記がありません。右下の＋で作成。'))
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = entries[i];
                return ListTile(
                  title: Text(e.title.isEmpty ? '(無題)' : e.title),
                  subtitle: Text(
                    e.content.isEmpty ? '本文なし' : e.content,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditorPage(entryId: e.id),
                      ),
                    );
                    ref.invalidate(entriesProvider);
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final id = DateTime.now().microsecondsSinceEpoch.toString();
          final box = ref.read(entriesBoxProvider);
          final entry = DiaryEntry(id: id, title: '', content: '');
          await box.put(id, entry);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditorPage(entryId: id, isNew: true),
            ),
          );
          ref.invalidate(entriesProvider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
