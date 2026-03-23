import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/user_settings_provider.dart';
import '../../datastore/user_settings_repository.dart';

/// ホワイトボード設定パネル
class WhiteboardSettingsPanel extends ConsumerWidget {
  const WhiteboardSettingsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.palette, color: Colors.purple.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'ホワイトボード設定',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'カスタム色設定',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '基本4色（黒・赤・緑・黄）に加えて、2色を自由に設定できます',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // 色5の選択
              Row(
                children: [
                  const Text('色5: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildColorSelector(
                    context,
                    ref,
                    settings,
                    isColor5: true,
                    currentColor: Color(settings.whiteboardColor5),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 色6の選択
              Row(
                children: [
                  const Text('色6: ',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  _buildColorSelector(
                    context,
                    ref,
                    settings,
                    isColor5: false,
                    currentColor: Color(settings.whiteboardColor6),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('エラー: $error'),
    );
  }

  Widget _buildColorSelector(BuildContext context, WidgetRef ref, settings,
      {required bool isColor5, required Color currentColor}) {
    final presetColors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
    ];

    return Wrap(
      spacing: 8,
      children: presetColors.map((color) {
        final isSelected = currentColor.toARGB32() == color.toARGB32();
        return GestureDetector(
          onTap: () async {
            final repository = ref.read(userSettingsRepositoryProvider);
            final newSettings = isColor5
                ? settings.copyWith(whiteboardColor5: color.toARGB32())
                : settings.copyWith(whiteboardColor6: color.toARGB32());
            await repository.saveSettings(newSettings);
            ref.invalidate(userSettingsProvider);
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.grey,
                width: isSelected ? 3 : 1,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
