# Flutter × Firebase で家族向け買い物リスト共有アプリを作ってクローズドテストまで辿り着いた話

## はじめに

2025年10月から約3ヶ月かけて、Flutter + Firebase で家族やグループ向けの買い物リスト共有アプリ「Go Shop」を開発し、2026年1月13日にGoogle Play Consoleのクローズドテストまで辿り着きました。

この記事では、個人開発での試行錯誤、つまずいたポイント、そして得られた知見を共有します。

## アプリ概要

**Go Shop** は、家族やグループで買い物リストをリアルタイム共有できるアプリです。

### 主な機能

- 📝 **グループ共有**: 家族や友人とリストを共有
- 🔄 **リアルタイム同期**: 変更が即座に全デバイスに反映
- 📱 **QRコード招待**: 簡単にメンバーを追加
- 🔁 **定期購入設定**: 定期的に買うものを自動管理
- 📴 **オフライン対応**: ネットなしでも利用可能
- 🔔 **プッシュ通知**: リスト変更を即座に通知

### 技術スタック

```yaml
Framework: Flutter 3.4+
State Management: Riverpod (traditional syntax)
Backend: Firebase (Auth + Firestore + Crashlytics)
Local Storage: Hive (キャッシュ + オフライン対応)
Monetization: AdMob
```

## アーキテクチャの進化

### Phase 1: Hive単独構成（2025年10月）

最初は「シンプルに始めよう」ということで、Hive単独で実装しました。

```dart
// 初期のシンプル構成
class HiveShoppingListRepository {
  Future<List<ShoppingList>> getAllLists() async {
    final box = await Hive.openBox<ShoppingList>('shopping_lists');
    return box.values.toList();
  }
}
```

**問題点**:

- 複数デバイス間での同期ができない
- データバックアップがない
- 端末紛失 = データ全損失

### Phase 2: Firebase追加でハイブリッド構成へ（2025年11月）

複数デバイス対応の要望を受けて、Firestoreを導入しました。

```dart
// ハイブリッドリポジトリパターン
class HybridShoppingListRepository {
  final HiveRepository _hive;
  final FirestoreRepository _firestore;

  Future<List<ShoppingList>> getAllLists() async {
    if (isOnline) {
      // Firestore優先で最新データ取得
      final lists = await _firestore.getAllLists();
      // Hiveにキャッシュ
      await _hive.cacheLists(lists);
      return lists;
    } else {
      // オフライン時はHiveから
      return await _hive.getAllLists();
    }
  }
}
```

### Phase 3: Firestore-First への転換（2025年12月）

「認証必須」の方針転換により、Hive優先からFirestore優先へ大幅リファクタリング。

```dart
// Firestore優先＋差分同期の最終形
class HybridSharedListRepository {
  // アイテム追加は差分のみ送信（90%削減）
  Future<void> addSingleItem(String listId, SharedItem item) async {
    if (isAuthenticated && isOnline) {
      // Firestoreに単一フィールド更新
      await _firestore.collection('sharedLists').doc(listId).update({
        'items.${item.itemId}': item.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    // Hiveにキャッシュ
    await _hive.addItem(listId, item);
  }
}
```

**効果**:

- リスト全体送信（~5KB）→ 単一アイテム（~500B）
- **データ転送量90%削減**

## つまずいたポイント Top 5

### 1. Riverpod の `late final Ref` 地獄

```dart
// ❌ 危険パターン（LateInitializationError）
class MyNotifier extends AsyncNotifier<Data> {
  late final Ref _ref;

  @override
  Future<Data> build() async {
    _ref = ref;  // 2回目の呼び出しでエラー！
    return fetchData();
  }
}

// ✅ 安全パターン
class MyNotifier extends AsyncNotifier<Data> {
  Ref? _ref;

  @override
  Future<Data> build() async {
    _ref ??= ref;  // null-aware代入
    return fetchData();
  }
}
```

**学び**: `AsyncNotifier.build()` は複数回呼ばれる可能性がある

### 2. AndroidManifest.xml の `<queries>` 配置ミス

```xml
<!-- ❌ 間違い：applicationタグ内 -->
<application>
  <queries>
    <intent>
      <action android:name="android.intent.action.PROCESS_TEXT"/>
    </intent>
  </queries>
</application>

<!-- ✅ 正解：manifestタグの直下 -->
<manifest>
  <application>
    <!-- ... -->
  </application>
  <queries>
    <intent>
      <action android:name="android.intent.action.PROCESS_TEXT"/>
    </intent>
  </queries>
</manifest>
```

**エラーメッセージ**: "Element queries is not allowed here"

### 3. Gradle Kotlin DSL の日本語コメント問題

```kotlin
// ❌ これがビルドエラーの原因
// デフォルトflavorをdevに設定（日本語コメント）
missingDimensionStrategy("default", "dev")

// ✅ 英語コメントに変更
// Set default flavor to dev
missingDimensionStrategy("default", "dev")
```

**エラー**: "Malformed \uxxxx encoding"

**学び**: Kotlin DSLはエンコーディングに敏感

### 4. QRコード招待の複雑化との戦い

**v1.0**: QRに全データ埋め込み（17フィールド、~600文字）
→ QRコードが複雑すぎてスキャン失敗

**v3.1**: 軽量化（5フィールド、~150文字）

```json
{
  "invitationId": "abc123",
  "groupId": "group_xyz",
  "securityKey": "secure_key",
  "type": "secure_qr_invitation",
  "version": "3.1"
}
```

→ 詳細はFirestoreから取得（75%削減）

### 5. デフォルトグループの重複問題

**問題**: サインアウト→サインイン時に前ユーザーのグループが残る

**原因**: Hive優先チェックでFirestoreの既存グループを見ていなかった

**解決策**: Firestore優先チェック + Hiveクリーンアップ

```dart
Future<void> createDefaultGroup() async {
  // 🔥 Firestoreを最初にチェック
  final firestoreGroups = await _firestore
      .collection('SharedGroups')
      .where('allowedUid', arrayContains: user.uid)
      .get();

  if (firestoreGroups.docs.any((doc) => doc.id == user.uid)) {
    // 既存グループ発見 → Hiveに同期
    await _syncToHive(firestoreGroups);
    // 不要なHiveデータを削除
    await _cleanupInvalidHiveGroups(user.uid);
    return;
  }

  // 存在しない場合のみ新規作成
  await _createNewDefaultGroup(user);
}
```

## リリース準備で大変だったこと

### 1. プライバシーポリシーの位置情報記載

AdMobの地域ターゲティングで位置情報を使うため、詳細な説明が必要でした。

**記載内容**:

- 収集目的: 広告配信の最適化**のみ**
- 精度: LocationAccuracy.low（約30km範囲）
- 頻度: 広告読み込み時のみ（1時間キャッシュ）
- 拒否可能: 拒否してもアプリ機能は全て利用可能

### 2. keystore署名設定の試行錯誤

```kotlin
// ❌ 失敗パターン（エンコーディングエラー）
val keystoreProperties = Properties()
keystoreProperties.load(FileInputStream(keystorePropertiesFile))

// ✅ 成功パターン
val keystoreProperties = Properties()
keystorePropertiesFile.reader().use {
  keystoreProperties.load(it)
}

signingConfigs {
  create("release") {
    keyAlias = keystoreProperties.getProperty("keyAlias")
    keyPassword = keystoreProperties.getProperty("keyPassword")
    storeFile = file(keystoreProperties.getProperty("storeFile"))
    storePassword = keystoreProperties.getProperty("storePassword")
  }
}
```

### 3. AABビルドの瞬間

```bash
$ flutter build appbundle --release --flavor prod

Running Gradle task 'bundleProdRelease'... 412.7s
√ Built build\app\outputs\bundle\prodRelease\app-prod-release.aab (57.6MB)
```

この412秒（約7分）が長かった…！

## 得られた知見

### 1. Firestoreのセキュリティルール設計

```javascript
// subcollectionのパーミッション注意点
match /SharedGroups/{groupId}/sharedLists/{listId} {
  // ❌ resource.dataは新規作成時に存在しない
  allow create: if resource.data.ownerUid == request.auth.uid;

  // ✅ 親ドキュメントから取得
  allow create: if get(/databases/$(database)/documents/SharedGroups/$(groupId))
                   .data.ownerUid == request.auth.uid;
}
```

### 2. Hiveのボックス管理

```dart
// ユーザー切り替え時の確実なクリーンアップ
Future<void> switchUser(String newUserId) async {
  // 1. 全ボックスを閉じる
  await Hive.close();

  // 2. Hiveを再初期化
  await Hive.initFlutter();

  // 3. ボックスを開き直す
  await Hive.openBox<SharedGroup>('SharedGroups');
  await Hive.openBox<SharedList>('sharedLists');
}
```

### 3. Riverpodのプロバイダー無効化タイミング

```dart
// ❌ 間違い：invalidateだけでは不完全
ref.invalidate(allGroupsProvider);
Navigator.push(...);  // まだ古いデータ

// ✅ 正解：更新完了を待つ
ref.invalidate(allGroupsProvider);
await ref.read(allGroupsProvider.future);  // 更新完了を待機
Navigator.push(...);  // 新しいデータで表示
```

### 4. 定期購入リセットの自動化

```dart
// アプリ起動時にバックグラウンド実行
Future<void> _resetPeriodicPurchaseItems() async {
  Future.delayed(const Duration(seconds: 5), () async {
    for (final list in allLists) {
      for (final item in list.activeItems) {
        if (item.isPurchased &&
            item.shoppingInterval > 0 &&
            item.purchaseDate != null) {
          final nextDate = item.purchaseDate!
              .add(Duration(days: item.shoppingInterval));
          if (DateTime.now().isAfter(nextDate)) {
            // 未購入状態に戻す
            await resetItem(item);
          }
        }
      }
    }
  });
}
```

## 開発期間とコミット数

```
期間: 2025年10月 〜 2026年1月（約3ヶ月）
コミット数: 約150件
主要言語: Dart 95%, Kotlin 3%, Swift 2%
総行数: 約15,000行
```

## 今後の予定

- ✅ クローズドテスト（2026年1月）← **今ココ**
- 🔲 オープンベータテスト（2026年2月予定）
- 🔲 正式リリース（2026年3月予定）
- 🔲 iOS版開発（2026年4月〜）

## まとめ

個人開発での「設計変更の柔軟性」と「品質担保」のバランスが難しかったですが、以下のポイントを意識することで何とかリリースまで辿り着けました：

1. **段階的なアーキテクチャ進化** - いきなり完璧を目指さない
2. **ログの充実** - 問題特定の時間が10倍変わる
3. **プロバイダーのテスト** - Riverpodの挙動を事前に確認
4. **ドキュメント化** - 自分が2週間後に忘れる前提で書く
5. **コミット粒度** - 小さく、頻繁に、意味のある単位で

「動くものを作る」から「使えるものにする」までの道のりは想像以上に長かったですが、実際にユーザーに使ってもらえる段階まで来られたことは大きな達成感があります。

クローズドテストでの反応が楽しみです！

## リンク

- [プライバシーポリシー](https://github.com/maya27AokiSawada/go_shop/blob/main/docs/specifications/privacy_policy.md)
- [利用規約](https://github.com/maya27AokiSawada/go_shop/blob/main/docs/specifications/terms_of_service.md)

---

この記事が、Flutterでの個人開発やFirebaseとの連携で悩んでいる方の参考になれば幸いです。
質問やフィードバックがあれば、コメント欄でお待ちしています！

# Flutter #Firebase #Riverpod #個人開発 #Firestore #Hive #AndroidApp
