import 'dart:math';

/// Contract for AI assistant features.
abstract class AiAssistantService {
  Future<String> suggest(String title, String content);
  Future<String> summarize(String content);
}

/// Mock implementation for local development.
class MockAiAssistantService implements AiAssistantService {
  static const _suggestions = [
    '今日の感情ときっかけを1行で書いてみましょう。',
    '具体的な行動と結果を短く追加してみてください。',
    '次にやってみたいことを1つだけ挙げてみませんか？',
    '感謝していることを3つメモすると気分が整います。',
  ];

  @override
  Future<String> suggest(String title, String content) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final rand = Random();
    final s = _suggestions[rand.nextInt(_suggestions.length)];
    final hint = content.trim().isEmpty
        ? 'まずは思いついたことから書き始めてみましょう。'
        : '今の内容をもう一歩具体化できます。人物・場所・時間・気持ちを1つ足してみて。';
    return 'ヒント: $s\n\n$hint';
  }

  @override
  Future<String> summarize(String content) async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (content.trim().isEmpty) return 'まだ本文が空のようです。まずは短く書いてみましょう。';
    final words = content
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    final brief = words.take(30).join(' ');
    return '要約 (仮): $brief${words.length > 30 ? ' …' : ''}';
  }
}
