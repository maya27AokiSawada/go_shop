# 開発日報 - 2026年08月11日

## 📅 本日の目標

- [x] ビルドが失敗する根本原因を特定・修正する
- [x] SH-54D (prod) で `flutter run` が通ることを確認する
- [x] 機種依存の設定ファイルを gitignore 管理に移行する

---

## ✅ 完了した作業

### 1. Flutter が JDK 25.0.2 を誤検出しビルド失敗する問題を修正 ✅

**Purpose**: `flutter run` / `flutter build apk` 実行時に `IllegalArgumentException: 25.0.2` でビルドが失敗していた問題を解消する。

**Background**: `./android/gradlew` 直接実行では成功するのに `flutter build apk` では失敗するという症状から調査を開始。

**Problem / Root Cause**:

```
FAILURE: Build failed with an exception.
* What went wrong:
25.0.2
java.lang.IllegalArgumentException: 25.0.2
```

- macOS に JDK 26.0.2 / 21.0.12 / 17.0.19 がインストールされているほか、Android Studio 経由で JDK 25.0.2 が存在した
- Flutter の Java 検出ロジックは `JAVA_HOME` より Android Studio の組み込み JDK を優先する場合がある
- 端末の `JAVA_HOME` は JDK 21 を指していたが、Flutter は JDK 25.0.2 を使用していた
- AGP 8.11.1 が JDK 25.0.2 のバージョン文字列をパースできず `IllegalArgumentException` を投げていた

**Solution**:

```properties
# android/gradle.properties に追加
org.gradle.java.home=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home
```

`gradle.properties` に `org.gradle.java.home` を明示することで、Flutter の JDK 検出を上書きし JDK 21 LTS を強制使用。

**検証結果**:

| コマンド                                       | 結果        |
| ---------------------------------------------- | ----------- |
| `flutter build apk --debug --flavor prod`      | ✅ 成功     |
| `flutter run --flavor prod -d 359705470227530` | ✅ 起動確認 |

**Modified Files**:

- `android/gradle.properties`（`org.gradle.java.home` を追加 → gitignore 管理に移行）

**Status**: ✅ 完了・実機確認済み

---

### 2. `android/gradle.properties` を gitignore 管理に移行 ✅

**Purpose**: `org.gradle.java.home` に macOS 固有のパスが含まれるため、Windows ビルドを壊さないよう追跡対象から除外する。

**Problem / Root Cause**:

- `gradle.properties` に記述した JDK パスは macOS 固有であり、Windows ビルド環境ではパスが存在せずエラーになる

**Solution**:

- `.gitignore` に `android/gradle.properties` を追加（`android/key.properties` と同等の扱い）
- `git rm --cached android/gradle.properties` でインデックスから削除（ファイル自体はローカルに保持）

**Modified Files**:

- `.gitignore`（`android/gradle.properties` を追加）

**Status**: ✅ 完了

---

### 3. `android/.settings/` を git 追跡から除外 ✅

**Purpose**: IDE 自動生成の機種固有設定ファイルが誤ってコミット対象になっていたため、追跡を解除する。

**Background**: `android/.settings/` はすでに `.gitignore` に記載されていたが、過去にインデックスへ追加されたまま残っていた。

**Solution**:

- `git rm --cached android/.settings/org.eclipse.buildship.core.prefs` でインデックスから削除

**Status**: ✅ 完了

---

## 🐛 発見された問題

### Flutter の Java 検出が JAVA_HOME より Android Studio JDK を優先する ✅

- **症状**: `JAVA_HOME=JDK 21` を設定していても Flutter が JDK 25.0.2 を使用する
- **原因**: Flutter は Android Studio のパスを `JAVA_HOME` より優先してスキャンする
- **対処**: `android/gradle.properties` に `org.gradle.java.home` を明示してオーバーライド
- **状態**: 修正完了（ローカル設定ファイルで管理）

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Flutter JDK 誤検出による `IllegalArgumentException` ビルド失敗（完了日: 2026-08-11）
2. ✅ `android/gradle.properties` の gitignore 管理移行（完了日: 2026-08-11）
3. ✅ `android/.settings/` の不要追跡解除（完了日: 2026-08-11）

### 対応中 🔄

1. なし

### 未着手 ⏳

1. なし

### 翌日継続 ⏳

- なし

---

## 💡 技術的学習事項

### Flutter の Java 検出優先順位に注意

**問題パターン**:

```
# JAVA_HOME を設定していても Flutter が別の JDK を使う場合がある
JAVA_HOME=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home
→ Flutter は Android Studio の組み込み JDK を優先することがある
```

**正しい対処パターン**:

```properties
# android/gradle.properties で JDK を明示固定する（機種依存のため gitignore 管理）
org.gradle.java.home=/path/to/jdk21
```

**教訓**:

- `flutter run/build` が Gradle 直接実行と異なる結果になる場合、JDK 検出の差異を疑う
- `flutter build apk --verbose` で Flutter が使用している JDK バージョンを確認できる
- `android/gradle.properties` は `android/key.properties` と同様にローカル設定ファイルとして gitignore 管理するのが適切

### JDK バージョン選択指針（2026年8月現在）

| バージョン | 種別   | 公開アプリ向き | 備考                                 |
| ---------- | ------ | -------------- | ------------------------------------ |
| JDK 21     | LTS    | ✅ 推奨        | AGP 8.x の公式推奨、2028-09 まで LTS |
| JDK 25     | LTS    | ✅ 移行候補    | 2025-09 リリース                     |
| JDK 26     | 非 LTS | ❌ 非推奨      | 6ヶ月サポートのみ                    |

---

## 🗓 翌日（2026-08-12）の予定

1. 特になし（ビルド環境は安定）

---

## 📝 ドキュメント更新

| ドキュメント     | 更新内容                                                 |
| ---------------- | -------------------------------------------------------- |
| 指示書更新: なし | 理由: ビルド環境の修正のみ。アーキテクチャ・仕様変更なし |

---

## セットアップ補足（SETUP.md 参照）

macOS でビルドする場合は `android/gradle.properties`（gitignore 対象）をローカルに作成し、以下を設定すること:

```properties
org.gradle.java.home=/Library/Java/JavaVirtualMachines/temurin-21.jdk/Contents/Home
org.gradle.jvmargs=-Xmx8G -XX:MaxMetaspaceSize=4G -XX:ReservedCodeCacheSize=512m -XX:+HeapDumpOnOutOfMemoryError
android.useAndroidX=true
android.enableJetifier=true
android.defaultFlavor=dev
android.builtInKotlin=false
android.newDsl=false
kotlin.incremental=false
kotlin.compiler.execution.strategy=in-process
org.gradle.parallel=false
org.gradle.workers.max=1
org.gradle.caching=false
kotlin.daemon.enabled=false
```
