# ホワイトボード機能指示書

> 共通ルールは `00_project_common.md` を先に読むこと。

---

## 1. レイヤー構成

- **CustomPaint**（背景レイヤー）: 保存済みストロークを描画
- **Signature**（前景レイヤー）: 現在描画中セッション（透明背景）
- 色・太さ変更時は `_captureCurrentDrawing()` → 新 `SignatureController` 作成

---

## 2. strokeId ベース差分保存（サブコレクション + fire-and-forget）

ストロークは `strokes/{strokeId}` **サブコレクション**に個別ドキュメントとして保存する。
保存時は **未保存 strokeId のみを送信**し（全件送信禁止）、`unawaited` で fire-and-forget する。

```dart
// 未保存 strokeId を追跡する Set
final Set<String> _unsavedStrokeIds = {};

// ペンアップ時に新規ストロークを未保存リストへ追加
void _captureCurrentStroke() {
  for (final stroke in strokes) {
    _unsavedStrokeIds.add(stroke.strokeId);
  }
}

// 保存時は未保存分のみ抽出 → fire-and-forget
final newStrokes = _workingStrokes
    .where((s) => _unsavedStrokeIds.contains(s.strokeId))
    .toList();
// ✅ unawaited: Firestoreオフライン永続化でローカルへの書き込みは即時完了
// サーバーACKを await する必要はなく、UIをブロックしない
unawaited(
  repository.addStrokesToSubcollection(
    groupId: groupId,
    whiteboardId: whiteboardId,
    newStrokes: newStrokes,
  ).catchError((e) {
    if (mounted) SnackBarHelper.showError(context, '保存に失敗しました');
  }),
);
strokeIds.forEach((s) => _unsavedStrokeIds.remove(s.strokeId));
```

**サブコレクション パス**: `SharedGroups/{groupId}/whiteboards/{wbId}/strokes/{strokeId}`

**注**: 旧 `addStrokesToWhiteboard`（arrayUnion）は廃止。strokes は全て subcollection で管理する。

---

## 3. Firestore リスナーの実装ルール

### 3-1. `watchStrokesSubcollection` — hasPendingWrites フィルター禁止

fire-and-forget 保存後のストロークは **pending write 状態**（サーバー未同期）のまま Stream に流れてくる。
`.where(!hasPendingWrites)` でフィルターすると**保存したばかりのストロークが表示されない**。

```dart
// ✅ 正しい — hasPendingWrites フィルターなし、クライアントソート
return _strokesCollection(groupId, whiteboardId)
    .snapshots()                       // orderBy は使わない（インデックス不要、FAILED_PRECONDITION回避）
    .handleError((e, stack) { AppLogger.error('Stream error: $e'); })
    .map((snapshot) => snapshot.docs
        .map((d) => DrawingStroke.fromFirestore(d.data()))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt))); // クライアントソート

// ❌ 禁止 — strokes サブコレクションで hasPendingWrites フィルターを使う
.where((s) => !s.metadata.hasPendingWrites) // pending write = fire-and-forget の書き込みを弾く

// ❌ 禁止 — .orderBy() をクエリに含める（インデックス未作成時に FAILED_PRECONDITION で無音終了）
.orderBy('createdAt')
```

### 3-2. リスナーの onError と cancelOnError

```dart
// ✅ 必須 — onError + cancelOnError: false でリスナーを継続させる
stream.listen(
  (data) { /* 処理 */ },
  onError: (e, stack) { AppLogger.error('リスナーエラー: $e'); },
  cancelOnError: false, // エラーが起きてもリスナーを継続
);
// ❌ 禁止 — onError なしの .listen() はエラーで無音終了する
```

### 3-3. `watchWhiteboard()` — hasPendingWrites スキップは任意

ホワイトボードのメタデータ（タイトル等）を監視する `watchWhiteboard()` は
pending write が問題にならない場合はフィルターしても良いが、必須ではない。

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

| 処理                        | Windows                         | Android / iOS |
| --------------------------- | ------------------------------- | ------------- |
| `addStrokesToSubcollection` | `batch.set()` — fire-and-forget | 同左          |
| `runTransaction`            | **禁止**（abort クラッシュ）    | 使用可        |
| ペンモード終了時 UI         | UI 先行リセット                 | 同左          |

**注**: 旧 `addStrokesToWhiteboard`（`arrayUnion` を使う `update()`）は廃止。全プラットフォームで `batch.set()` に統一。

---

## 6. 禁止事項

- 点間距離（distance）による stroke 分割（iOS で誤分割が多発する）
  - `signature` パッケージの `PointType` 境界を使うこと
- strokes サブコレクションで `.where(!hasPendingWrites)` フィルターを使う（fire-and-forget の pending write を弾くため）
- `watchStrokesSubcollection` に `.orderBy()` を追加する（インデックス未作成時に FAILED_PRECONDITION で無音終了するため）
- strokes 以外のリスナー（`watchWhiteboard()` 等）で hasPendingWrites 状態のスナップショットをそのまま UI に流すのは非推奨
- `_currentDeviceId` 未確定状態での `_watchEditLock()` 起動
- Windows で `runTransaction()` を使う
- `isPrivate` 等トグル値を「現在値の反転」で保存する（目標値を直接保存すること）
