# Go Shop - プライバシー保護方針

## メンバープールのプライバシー保護

### 🔒 基本方針

Go Shopアプリでは、個人情報保護を最優先に考え、メンバープール（連絡先情報）については以下の方針を採用しています。

### 📱 ローカル保存のみ

- **メンバープール**: Hiveローカルデータベースにのみ保存
- **連絡先情報**: デバイス外への送信を一切行わない
- **Firestore同期**: メンバープールは意図的に同期対象外

### 🛡️ 実装上の保護措置

#### HybridPurchaseGroupRepository

```dart
/// メンバープールは個人情報保護の観点からHiveローカルDBにのみ保存
/// Firestoreには一切同期しない
Future<PurchaseGroup> getOrCreateMemberPool() async {
  // 🔒 個人情報保護: メンバープールはローカルのみ
  return await _hiveRepo.getOrCreateMemberPool();
}
```

#### FirestorePurchaseGroupRepository

```dart
Future<PurchaseGroup> getOrCreateMemberPool() async {
  throw UnimplementedError('🔒 Member pool is local-only for privacy protection');
}
```

### 🔄 データの分類

| データ種類 | ローカル | Firestore | 理由 |
|-----------|---------|-----------|------|
| **メンバープール** | ✅ | ❌ | 個人情報保護 |
| 購入グループ | ✅ | ✅ | 共有必要 |
| ショッピングリスト | ✅ | ✅ | 共有必要 |
| 招待情報 | - | ✅ | 一時的なメタデータ |

### 💡 メリット

1. **プライバシー保護**: 連絡先情報がクラウドに送信されない
2. **GDPR準拠**: 個人データのローカル管理
3. **セキュリティ**: ネットワーク経由での漏洩リスクゼロ
4. **高速アクセス**: ローカルDBによる高速な検索・表示

### ⚠️ 注意点

- メンバープールはデバイス間で同期されません
- バックアップは各デバイスで個別に管理してください
- アプリ再インストール時にはメンバープールデータは失われます

### 🎯 今後の展開

この個人情報保護方針により、ユーザーは安心してGo Shopアプリを利用でき、プライバシーを損なうことなく便利な買い物リスト共有機能を享受できます。