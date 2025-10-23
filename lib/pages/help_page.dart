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
      title: '� UI操作ガイド',
      content: '''
# UI操作ガイド

アプリの基本的な画面操作とアクションの説明です。

## 🏠 ホーム画面
**画面下部のナビゲーション**
- 📱 **タップ**: ホーム → ホーム画面表示
- 📱 **タップ**: グループ → グループ管理画面
- 📱 **タップ**: 買い物リスト → ショッピングリスト画面

## 👥 グループ管理画面

### ヘッダー部分
- 📱 **同期ボタン（🔄）タップ**: Firestore手動同期実行
- 📱 **カレント情報**: 現在選択中のグループ表示

### グループリスト
- 📱 **グループタップ**: カレントグループに設定
  - 青いハイライト表示に変更
  - 「カレント」バッジ表示
  - 成功メッセージ表示
- 📱 **設定ボタン（⚙️）タップ**: メンバー管理画面に遷移
- 📱 **グループ長押し**: 削除オプション表示（オーナーのみ）
- 📱 **右下+ボタンタップ**: 新規グループ作成

### 視覚的表示
- 🎨 **青いハイライト**: カレントグループ
- 🎨 **チェックアイコン**: 選択中マーク
- 🎨 **「カレント」バッジ**: 現在のアクティブグループ
- 🎨 **メンバー数バッジ**: 緑色の数字表示

## 🛒 ショッピングリスト画面

### グループ選択
- 📱 **ドロップダウンタップ**: グループ切り替え
- 📱 **リスト選択**: そのグループのショッピングリスト表示

### アイテム操作  
- 📱 **アイテムタップ**: 購入状態切り替え
- 📱 **アイテム長押し**: 編集・削除メニュー
- 📱 **右上+ボタンタップ**: 新規アイテム追加

## 👤 メンバー管理画面

### メンバーリスト
- 📱 **メンバータップ**: 詳細表示・編集
- 📱 **削除ボタンタップ**: メンバー削除（確認あり）
- 📱 **役割変更**: オーナー・管理者・メンバー切り替え

### 招待機能
- 📱 **「メンバー招待」ボタンタップ**: 招待方法選択
- 📱 **QRコード招待**: QRコード生成・表示
- 📱 **メール招待**: メール送信画面起動
- 📱 **手動追加**: 名前・連絡先直接入力

## 🎯 操作のコツ

### 効率的な使い方
1. **カレントグループ設定**: よく使うグループをタップで固定
2. **ショッピングリスト**: カレントグループが自動選択される
3. **メンバー管理**: 設定ボタンで素早くアクセス
4. **削除操作**: 長押しで安全に削除（確認ダイアログあり）

### 権限による機能制限
- **オーナーのみ**: グループ削除、全メンバー管理
- **管理者**: メンバー招待・編集可能
- **メンバー**: 閲覧・アイテム追加のみ
''',
      keywords: ['UI', '操作', 'タップ', '長押し', 'ナビゲーション', 'ボタン', 'アクション'],
    ),
    const HelpSection(
      title: '�👥 グループ管理',
      content: '''
# グループ管理

## グループを作成する
1. 「グループ」タブをタップ
2. 右下の「+」ボタンをタップ
3. グループ名を入力
4. 「作成」ボタンをタップ

作成者は自動的に「オーナー」として設定されます。

## カレントグループを選択する
1. 「グループ」タブでグループ一覧を表示
2. 使用したいグループを **タップ**
3. 青いハイライトと「カレント」バッジで確認
4. ショッピングリストでそのグループが使用される

## メンバーを管理する
1. グループの **設定ボタン（⚙️）をタップ**
2. メンバー管理画面に遷移
3. 「メンバー招待」で新規追加
4. 既存メンバーは **タップで編集**

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
1. グループを **長押し**
2. 「削除」を選択
3. 確認ダイアログで「削除」をタップ

⚠️ オーナーのみがグループを削除できます。
''',
      keywords: ['グループ', 'メンバー', '追加', '削除', '役割', 'オーナー', '管理者', 'カレント'],
    ),
    const HelpSection(
      title: '🛒 買い物リスト',
      content: '''
# 買い物リスト

## 画面構成と基本操作

### 上部エリア
- 📱 **グループドロップダウンタップ**: グループ切り替え
  - カレントグループが自動選択される
  - 他のグループへも切り替え可能
- 📱 **右上リスト追加ボタン（📝）タップ**: 新しいショッピングリスト作成
- 📱 **右上メニューボタン（⋮）タップ**: オプションメニュー
  - 「購入済みアイテムを削除」選択可能

### アイテムリスト操作
- 📱 **アイテムタップ**: 購入状態の切り替え
  - 未購入 ↔ 購入済み
  - 購入済みアイテムは色が薄くなりチェックマーク表示
- 📱 **アイテム長押し**: 編集・削除メニュー表示
  - 編集、削除、詳細表示など
- 📱 **右下+ボタンタップ**: 新規アイテム追加ダイアログ

## アイテム追加の詳細手順
1. **買い物リスト**タブをタップ
2. **右下の+ボタン**をタップ
3. **商品名**を入力
4. **数量**を設定（デフォルト1）
5. **期限**を設定（オプション）
6. **定期購入**設定（オプション）
7. **「追加」ボタン**をタップ

## アイテム編集・削除
1. **アイテムを長押し**
2. メニューから選択：
   - **「編集」**: 商品名、数量、期限を変更
   - **「削除」**: 確認後にアイテム削除
   - **「詳細」**: アイテム詳細情報表示

## 購入状態管理
- 📱 **アイテム1回タップ**: 購入状態切り替え
  - 🔲 未購入 → ✅ 購入済み
  - ✅購入済み → 🔲 未購入
- 🎨 **視覚的フィードバック**: 
  - 購入済み: 薄いグレー表示＋チェックマーク
  - 未購入: 通常の濃い色表示

## 定期購入アイテム
**設定方法**:
1. アイテム編集で「定期購入」を**ON**
2. **購入間隔**（日数）を設定
3. **自動的に次回期限**が計算される

**表示**: 🔄マークで定期購入アイテムを識別

## リスト整理機能
- 📱 **メニュー** → **「購入済みアイテムを削除」**: 一括クリア
- **自動並び替え**: 
  - 未購入アイテムが上部
  - 期限の近いものが優先表示
  - 購入済みアイテムが下部

## グループ間の切り替え
- 📱 **ドロップダウンタップ**: 他のグループのリストに切り替え
- 📱 **グループタブでカレント変更**: メインで使うグループを設定
- 🔄 **リアルタイム同期**: グループメンバー間で即座に共有
''',
      keywords: [
        '買い物',
        'リスト',
        'アイテム',
        '追加',
        '削除',
        '購入',
        '定期購入',
        'クリア',
        'タップ',
        '長押し'
      ],
    ),
    const HelpSection(
      title: '📲 招待・参加機能',
      content: '''
# 招待・参加機能

## メンバー招待の手順

### 1. 招待画面へのアクセス
1. **「グループ」タブ**をタップ
2. グループの**設定ボタン（⚙️）**をタップ
3. **「メンバー招待」ボタン**をタップ
4. 招待方法を選択

### 2. QRコード招待
**📱 QRコード生成**:
1. **「QRコード招待」**を選択
2. QRコードが自動生成される
3. **「共有」ボタン**タップで共有方法選択
   - スクリーンショット保存
   - SNS・メール送信
   - 画面表示して直接読み取り

**📱 QRコード参加**:
1. **「QR読み取り」**を選択（または右上QRアイコン）
2. **カメラでQRコード**を読み取り
3. グループ情報確認
4. **「参加」ボタン**をタップ

### 3. メール招待
1. **「メール招待」**を選択
2. **宛先メールアドレス**を入力
3. **「送信」ボタン**をタップ
4. 相手がメールのリンクから参加

### 4. 手動追加
**オーナー・管理者のみ**:
1. **「手動追加」**を選択
2. **名前**を入力
3. **連絡先**（メールまたは電話）を入力
4. **役割**を選択（メンバー・管理者）
5. **「追加」ボタン**をタップ

## メンバー管理画面の操作

### メンバーリスト表示
- 📱 **メンバーカード**: 名前、役割、連絡先表示
- 📱 **役割バッジ**: オーナー（王冠）・管理者（盾）・メンバー（人）
- 📱 **オンライン状態**: 最終ログイン時刻表示

### メンバー編集・削除
**📱 メンバーカードタップ**:
- 詳細情報表示
- 役割変更（権限があれば）
- 連絡先編集

**📱 削除ボタンタップ**:
- 確認ダイアログ表示
- オーナー・管理者のみ実行可能
- 自分自身は削除不可

### 権限による操作制限
**🏆 オーナー**:
- 全メンバーの招待・編集・削除
- 役割変更（管理者任命など）
- QRコード招待作成

**🛡️ 管理者**:
- メンバー招待・編集・削除
- QRコード招待作成
- 他の管理者・オーナーは編集不可

**👤 メンバー**:
- 閲覧のみ
- QRコードスキャンでの参加のみ可能

## 招待リンクとQRコード

### QRコードの特徴
- **24時間有効**: セキュリティのため期限付き
- **1回使用**: 使用後は自動的に無効化
- **グループ情報含有**: グループ名、招待者情報を表示

### 招待を受ける側の操作
1. **QRコード読み取り**または**招待リンクタップ**
2. **グループ情報確認画面**表示
   - グループ名
   - 招待者名
   - メンバー数
3. **「参加する」ボタン**をタップ
4. **ユーザー情報入力**（初回のみ）
5. **参加完了**→ グループリストに追加

## トラブルシューティング

**QRコードが読み取れない**:
- 📱 カメラの焦点を合わせ直す
- 📱 明るい場所で再試行
- 📱 QRコードの期限切れを確認

**招待リンクが開けない**:
- 📱 アプリがインストールされているか確認
- 📱 リンクの期限切れを確認
- 📱 手動でアプリを開いてQRスキャン

**メンバー追加ができない**:
- 📱 招待権限があるか確認（オーナー・管理者のみ）
- 📱 ネット接続状況を確認
- 📱 相手が既に他のグループにいる可能性
''',
      keywords: ['招待', 'QRコード', '参加', 'メンバー', '追加', 'メール', '手動', '権限', 'リンク'],
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
      final titleMatch =
          section.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final contentMatch =
          section.content.toLowerCase().contains(_searchQuery.toLowerCase());
      final keywordMatch = section.keywords.any((keyword) =>
          keyword.toLowerCase().contains(_searchQuery.toLowerCase()));

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
      final filteredLines = lines
          .where(
              (line) => line.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();

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
      } else if (line.trim().startsWith('⚠️') ||
          line.trim().startsWith('**Q:') ||
          line.trim().startsWith('**A:')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: line.trim().startsWith('⚠️')
                ? Colors.orange[50]
                : Colors.blue[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: line.trim().startsWith('⚠️') ? Colors.orange : Colors.blue,
              width: 1,
            ),
          ),
          child: Text(
            line.trim(),
            style: TextStyle(
              fontWeight: line.trim().startsWith('**')
                  ? FontWeight.bold
                  : FontWeight.normal,
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
