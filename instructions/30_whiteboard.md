# ホワイトボード機能指示書

> 共通ルールは `00_project_common.md` を先に読むこと。

---

## 1. レイヤー構成

- **CustomPaint**（背景レイヤー）: 保存済みストロークを描画
- **Signature**（前景レイヤー）: 現在描画中セッション（透明背景）
- 色・太さ変更時は `_captureCurrentDrawing()` → 新 `SignatureController` 作成

---

## 2. strokeId ベース差分保存

保存時は **未保存 strokeId のみを送信**する（全件送信禁止）。

```dart
// 未保存 strokeId を追跡する Set
final Set<String> _unsavedStrokeIds = {};

// ペンアップ時に新規ストロークを未保存リストへ追加
void _captureCurrentStroke() {
  for (final stroke in strokes) {
    _unsavedStrokeIds.add(stroke.strokeId);
  }
}

// 保存時は未保存分のみ抽出
final newStrokes = _workingStrokes
    .where((s) => _unsavedStrokeIds.contains(s.strokeId))
    .toList();
await repository.addStrokesToWhiteboard(
  groupId: groupId,
  whiteboardId: whiteboardId,
  newStrokes: newStrokes,
);
// 保存後にリストから削除
newStrokes.forEach((s) => _unsavedStrokeIds.remove(s.strokeId));
```

---

## 3. Firestore リスナーのマージ処理

`watchWhiteboard()` / `watchEditLock()` は **`hasPendingWrites` スナップショットをスキップ**する。

```dart
// ✅ 必須
return docRef.snapshots()
    .where((snapshot) => !snapshot.metadata.hasPendingWrites)
    .map((snapshot) => Whiteboard.fromFirestore(snapshot.data()!, snapshot.id));
```

リスナーでストロークを受信した際は `strokeId` ベースでマージし、
**未保存のローカルストロークを消さない**ようにする。

---

## 4. 編集ロック

### userId + deviceId で所有者を判定する

```dart
// ✅ 正しい — userId だけでは同一ユーザー別端末を誤認する
final isMyLock = lockInfo != null &&
    lockInfo.userId == currentUser?.uid &&
    (lockInfo.deviceId == null ||          // legacy 互換
        lockInfo.deviceId == _currentDeviceId);
```

### `_loadCurrentDeviceId()` 完了後に `_watchEditLock()` を起動する

```dart
// ✅ 正しい
_loadCurrentDeviceId().then((_) {
  if (!mounted) return;
  _watchEditLock();
});

// ❌ 禁止 — deviceId 未確定のまま lock 監視を開始すると自端末 lock を誤認
_loadCurrentDeviceId();  // 完了を待たない
_watchEditLock();
```

### ロック取得タイムアウト

- `acquireEditLock()` に **8 秒タイムアウト**を付ける
- ロック取得失敗 + 実編集なし → 楽観的にペンモードへ移行（後から `watchEditLock` で補正）
- 同一ユーザー別端末の stale lock は強制引き継ぎ可

### UI のモード切替中はボタン二重タップを防止する

```dart
bool _isTogglingMode = false;

onPressed: _isTogglingMode ? null : () async {
  setState(() { _isTogglingMode = true; });
  try { /* ロック取得 */ } finally {
    setState(() { _isTogglingMode = false; });
  }
},
```

---

## 5. プラットフォーム差異

| 処理                     | Windows                       | Android / iOS      |
| ------------------------ | ----------------------------- | ------------------ |
| `addStrokesToWhiteboard` | 通常 `update()`               | `runTransaction()` |
| `runTransaction`         | **禁止**（abort クラッシュ）  | 使用可             |
| ペンモード終了時 UI      | UI 先行リセット（3s timeout） | 同左               |

---

## 6. 禁止事項

- 点間距離（distance）による stroke 分割（iOS で誤分割が多発する）
  - `signature` パッケージの `PointType` 境界を使うこと
- `hasPendingWrites = true` スナップショットをそのまま UI に流す
- `_currentDeviceId` 未確定状態での `_watchEditLock()` 起動
- Windows で `runTransaction()` を使う
- `isPrivate` 等トグル値を「現在値の反転」で保存する（目標値を直接保存すること）
