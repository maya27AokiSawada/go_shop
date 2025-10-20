import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

class TestGroupPage extends ConsumerWidget {
  const TestGroupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('テストグループページ'),
        backgroundColor: const Color(0xFF2E8B57),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'グループ選択テスト',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: null,
                      hint: const Text('グループを選択してください'),
                      items: [
                        'マイグループ',
                        'テストグループ1',
                        'テストグループ2',
                      ].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        Log.info('📋 [TEST] 選択されました: $newValue');
                        if (newValue != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$newValue を選択しました')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ボタンテスト',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Log.info('📋 [TEST] ボタン1がタップされました');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ボタン1がタップされました')),
                            );
                          },
                          child: const Text('テストボタン1'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            Log.info('📋 [TEST] ボタン2がタップされました');
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('ボタン2がタップされました')),
                            );
                          },
                          child: const Text('テストボタン2'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Log.info('📋 [TEST] フローティングボタンがタップされました');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('フローティングボタンがタップされました')),
          );
        },
        backgroundColor: const Color(0xFF2E8B57),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}