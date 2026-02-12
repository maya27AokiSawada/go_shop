/// 多言語対応システムの使用例
///
/// このファイルは、実際のコードで使用する際の参考例です。

import 'package:flutter/material.dart';
import 'package:goshopping/l10n/l10n.dart';

/// 使用例1: 基本的なテキスト表示
class Example1BasicUsage extends StatelessWidget {
  const Example1BasicUsage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 方法1: グローバルショートカット（推奨）
        Text(texts.groupName),

        // 方法2: AppLocalizationsから直接取得
        Text(AppLocalizations.current.createGroup),
      ],
    );
  }
}

/// 使用例2: ボタンのラベル
class Example2ButtonLabels extends StatelessWidget {
  const Example2ButtonLabels({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: () {},
          child: Text(texts.save),
        ),
        OutlinedButton(
          onPressed: () {},
          child: Text(texts.cancel),
        ),
      ],
    );
  }
}

/// 使用例3: ダイアログ
class Example3Dialog extends StatelessWidget {
  const Example3Dialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(texts.confirmDeleteGroup),
      content: Text(texts.cannotBeUndone),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(texts.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            // 削除処理
            Navigator.pop(context);
          },
          child: Text(texts.delete),
        ),
      ],
    );
  }
}

/// 使用例4: フォームバリデーション
class Example4FormValidation extends StatelessWidget {
  const Example4FormValidation({super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: texts.groupName,
        hintText: texts.groupNameRequired,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return texts.groupNameRequired;
        }
        return null;
      },
    );
  }
}

/// 使用例5: スナックバー
class Example5Snackbar {
  static void showSuccess(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texts.groupCreated)),
    );
  }

  static void showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texts.networkError)),
    );
  }
}

/// 使用例6: 言語切り替え
class Example6LanguageSwitcher extends StatelessWidget {
  const Example6LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: AppLocalizations.currentLanguageCode,
      items: AppLocalizations.supportedLanguages.map((lang) {
        return DropdownMenuItem(
          value: lang,
          child: Text(AppLocalizations.getLanguageName(lang)),
        );
      }).toList(),
      onChanged: (newLang) {
        if (newLang != null) {
          try {
            AppLocalizations.setLanguage(newLang);
            // UIを再構築する必要がある場合がある
            // 例: setState(() {}) または Provider/Riverpodで管理
          } catch (e) {
            // 未実装の言語の場合
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$newLang は未対応です')),
            );
          }
        }
      },
    );
  }
}

/// 使用例7: 複数のテキストを組み合わせる
class Example7CombinedText extends StatelessWidget {
  const Example7CombinedText({super.key});

  @override
  Widget build(BuildContext context) {
    final memberCount = 5;

    return Column(
      children: [
        // 単純な組み合わせ
        Text('${texts.group}: ${texts.groupMembers}'),

        // 数値との組み合わせ
        Text('$memberCount${texts.people}'),

        // 複雑な組み合わせ
        Text('${texts.lastSyncTime}: ${texts.justNow}'),
      ],
    );
  }
}
