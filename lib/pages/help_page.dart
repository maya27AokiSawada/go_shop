import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ヘルプページ - ユーザーガイドと検索機能
class HelpPage extends ConsumerStatefulWidget {
  const HelpPage({super.key});

  @override
  ConsumerState<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends ConsumerState<HelpPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showBuiltInHelp = true; // 内蔵ヘルプ表示フラグ
  String _markdownContent = ''; // 外部マークダウンコンテンツ
  
  // ヘルプセクション
  final List<HelpSection> _helpSections = [
    const HelpSection(
      title: '📋 はじめに',
      content: '''
# Go Shop へようこそ！

Go Shop は家族やグループで買い物リストを共有できるアプリです。
リアルタイム同期により、メンバー間で常に最新の買い物リストを共有できます。

## 主な機能
- グループでの買い物リスト共有
- リアルタイム同期
- オフライン対応
- メンバー管理
''',
      keywords: ['はじめに', '概要', '機能', 'Go Shop'],
    ),
    
    const HelpSection(
      title: '👥 グループ管理',
      content: '''
# グループ管理

## グループを作成する
1. 「グループ」タブをタップ
2. 右下の「+」ボタンをタップ
3. グループ名を入力
4. 「作成」ボタンをタップ

作成者は自動的に「オーナー」として設定されます。

## メンバーを追加する
1. グループを選択
2. 「メンバー追加」をタップ
3. 名前と連絡先を入力
4. 役割を選択（メンバー・管理者）
5. 「追加」をタップ

## 役割について
- **オーナー**: グループの作成者、全権限あり
  - メンバー招待、役割変更、グループ削除が可能
  - QRコード招待の作成ができる
- **管理者**: メンバー管理、リスト編集可能  
  - メンバー招待、役割変更が可能
  - QRコード招待の作成ができる
- **メンバー**: リスト閲覧、アイテム追加可能
  - 招待権限なし（QRコードスキャンでの参加のみ可能）

## グループを削除する
1. グループを長押し
2. 「削除」を選択
3. 確認ダイアログで「削除」をタップ

⚠️ オーナーのみがグループを削除できます。
''',
      keywords: ['グループ', 'メンバー', '追加', '削除', '役割', 'オーナー', '管理者'],
    ),
    
    const HelpSection(
      title: '🛒 買い物リスト',
      content: '''
# 買い物リスト

## 買い物アイテムを追加する
1. 「買い物リスト」タブをタップ
2. 右下の「+」ボタンをタップ
3. 商品名を入力
4. 数量を設定
5. 「追加」をタップ

## アイテムを購入済みにする
- アイテムをタップすると購入状態が切り替わります
- 購入済みアイテムは色が変わり、チェックマークが表示されます

## アイテムを削除する
1. 削除したいアイテムを長押し
2. 「削除」を選択
3. 確認ダイアログで「削除」をタップ

## 定期購入アイテム
頻繁に購入するアイテムは「定期購入」として設定できます：
1. アイテム編集画面で「定期購入」をON
2. 購入間隔（日数）を設定
3. 自動的に期限が設定されます

## リストをクリアする
1. メニューボタン（⋮）をタップ
2. 「リストをクリア」を選択
3. 確認ダイアログで「クリア」をタップ

すべての購入済みアイテムが削除されます。
''',
      keywords: ['買い物', 'リスト', 'アイテム', '追加', '削除', '購入', '定期購入', 'クリア'],
    ),
    
    const HelpSection(
      title: '⚙️ 設定とカスタマイズ',
      content: '''
# 設定とカスタマイズ

## ユーザー名を変更する
1. ホーム画面のユーザー名をタップ
2. 新しい名前を入力
3. 「保存」をタップ

## 通知設定
現在開発中の機能です。将来のアップデートで追加予定です。

## データのバックアップ
アプリのデータは自動的にクラウドに同期されます：
- インターネット接続時に自動同期
- オフライン時はローカルに保存
- オンライン復帰時に自動でクラウドと同期

## アプリについて
- バージョン: 1.0.0
- 開発者: 青木沢田 真矢
- お問い合わせ: maya27AokiSawada@example.com
''',
      keywords: ['設定', 'ユーザー名', '変更', '通知', 'バックアップ', '同期', 'バージョン'],
    ),
    
    const HelpSection(
      title: '🔧 トラブルシューティング',
      content: '''
# トラブルシューティング

## アプリが起動しない
1. アプリを完全に終了
2. 数秒待ってから再起動
3. 問題が続く場合は端末を再起動

## データが同期されない
1. インターネット接続を確認
2. アプリを再起動
3. 「🧪」ボタンからテストページで同期状態を確認

## メンバーが追加できない
- オーナーまたは管理者権限が必要です
- 役割を確認してください

## 買い物アイテムが消えた
1. グループが正しく選択されているか確認
2. 他のメンバーが削除した可能性があります
3. テストページでデータ確認を実行

## その他の問題
以下の情報と共にお問い合わせください：
- 発生した問題の詳細
- 操作手順
- エラーメッセージ（表示された場合）
- 使用端末・OS情報

## よくある質問

**Q: オフラインでも使用できますか？**
A: はい。オフライン時もアプリは正常に動作し、オンライン復帰時に自動同期されます。

**Q: 何人までメンバーを追加できますか？**
A: 現在、メンバー数に制限はありません。

**Q: データは安全ですか？**
A: はい。すべてのデータは暗号化されてクラウドに保存されます。
''',
      keywords: ['トラブル', 'エラー', '起動しない', '同期されない', 'よくある質問', 'FAQ', '問題', '解決'],
    ),
    
    const HelpSection(
      title: '📱 便利な使い方',
      content: '''
# 便利な使い方

## 効率的な買い物リスト作成
1. **カテゴリ別に整理**: 野菜、肉類、日用品など
2. **定期購入を活用**: よく買う商品は定期購入設定
3. **数量を明確に**: 「牛乳 1L」など具体的に記載

## 家族での活用例
- **お父さん**: 仕事帰りの買い物用にリストをチェック
- **お母さん**: 家にあるものを確認してリストを更新
- **お子さん**: 欲しいお菓子をリストに追加

## グループ運用のコツ
1. **役割分担**: 管理者は複数人設定がおすすめ
2. **定期的な整理**: 不要なアイテムは定期的に削除
3. **コミュニケーション**: 大きな買い物は事前に相談

## ショートカット操作
- **ダブルタップ**: アイテムの詳細編集
- **長押し**: アイテム削除メニュー
- **左右スワイプ**: 購入状態の切り替え（将来実装予定）

## データ管理のヒント
- 定期的にリストをクリアして整理
- 重要なアイテムは優先度を設定（将来実装予定）
- 過去の購入履歴を活用（将来実装予定）
''',
      keywords: ['便利', '使い方', 'コツ', 'ショートカット', '効率', '家族', '活用'],
    ),
  ];
  
  List<HelpSection> get _filteredSections {
    if (_searchQuery.isEmpty) {
      return _helpSections;
    }
    
    return _helpSections.where((section) {
      final titleMatch = section.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final contentMatch = section.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final keywordMatch = section.keywords.any(
        (keyword) => keyword.toLowerCase().contains(_searchQuery.toLowerCase())
      );
      
      return titleMatch || contentMatch || keywordMatch;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadUserGuideMarkdown();
  }

  // ユーザーガイドマークダウンファイルを読み込み
  Future<void> _loadUserGuideMarkdown() async {
    try {
      final String content = await rootBundle.loadString('docs/user_guide.md');
      setState(() {
        _markdownContent = content;
      });
    } catch (e) {
      // ファイルが見つからない場合は内蔵ヘルプのみ表示
      setState(() {
        _markdownContent = '# ユーザーガイドファイルが見つかりません\n\n内蔵ヘルプをご利用ください。';
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('📖 ヘルプ'),
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          bottom: TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: '🔧 内蔵ヘルプ'),
              Tab(text: '📄 ユーザーガイド'),
            ],
            onTap: (index) {
              setState(() {
                _showBuiltInHelp = index == 0;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
        ),
        body: Column(
          children: [
            // 検索バー
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: _showBuiltInHelp ? '内蔵ヘルプを検索...' : 'ユーザーガイドを検索...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            // コンテンツ
            Expanded(
              child: TabBarView(
                children: [
                  _buildBuiltInHelpContent(),
                  _buildUserGuideContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 内蔵ヘルプコンテンツを構築
  Widget _buildBuiltInHelpContent() {
    final filteredSections = _filteredSections;
    
    if (filteredSections.isEmpty && _searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '「$_searchQuery」に関するヘルプが見つかりません',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '他のキーワードで検索してみてください',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredSections.length,
      itemBuilder: (context, index) {
        final section = filteredSections[index];
        return _buildHelpSection(section);
      },
    );
  }

  // ユーザーガイドコンテンツを構築
  Widget _buildUserGuideContent() {
    String displayContent = _markdownContent;
    
    // 検索フィルタリング
    if (_searchQuery.isNotEmpty) {
      final lines = _markdownContent.split('\n');
      final filteredLines = lines.where((line) => 
        line.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
      
      if (filteredLines.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '「$_searchQuery」に関する情報が見つかりません',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '他のキーワードで検索してみてください',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }
      
      displayContent = filteredLines.join('\n');
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _buildMarkdownContent(displayContent),
        ),
      ),
    );
  }

  Widget _buildHelpSection(HelpSection section) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          section.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMarkdownContent(section.content),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.local_offer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'タグ: ${section.keywords.join(', ')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkdownContent(String content) {
    final lines = content.split('\n');
    final widgets = <Widget>[];
    
    for (final line in lines) {
      if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            line.substring(2),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            line.substring(3),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ));
      } else if (line.startsWith('- **') && line.contains('**:')) {
        final parts = line.substring(2).split('**:');
        if (parts.length >= 2) {
          widgets.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• '),
                Text(
                  '${parts[0].replaceAll('**', '')}:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(parts[1]),
                ),
              ],
            ),
          ));
        }
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• '),
              Expanded(child: Text(line.substring(2))),
            ],
          ),
        ));
      } else if (line.trim().startsWith('⚠️') || line.trim().startsWith('**Q:') || line.trim().startsWith('**A:')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: line.trim().startsWith('⚠️') ? Colors.orange[50] : Colors.blue[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: line.trim().startsWith('⚠️') ? Colors.orange : Colors.blue,
              width: 1,
            ),
          ),
          child: Text(
            line.trim(),
            style: TextStyle(
              fontWeight: line.trim().startsWith('**') ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ));
      } else if (line.trim().isNotEmpty) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(line),
        ));
      } else {
        widgets.add(const SizedBox(height: 8));
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class HelpSection {
  final String title;
  final String content;
  final List<String> keywords;

  const HelpSection({
    required this.title,
    required this.content,
    required this.keywords,
  });
}