# 開発日報 - 2026年06月25日

## 📅 本日の目標

- [x] Kotlin 2.4.0 アップグレード後のビルドエラー（languageVersion 1.6 未サポート）を修正する
- [x] ビルド番号を 18 へインクリメントする

---

## ✅ 完了した作業

### 1. Kotlin language version 1.6 未サポートエラーの修正 ✅

**Purpose**: Kotlin 2.4.0 へのアップグレード後に発生したビルドエラーを解消し、Android ビルドを安定化する

**Background**:

2026-06-24 に Kotlin を 2.1.0 → 2.4.0 へアップグレードし、`kotlinOptions` DSL を `compilerOptions` DSL へ移行した。
しかし Kotlin 2.4.0 は `languageVersion = 1.6` のサポートを廃止しており、`sentry_flutter` をはじめとする一部サードパーティプラグインが依然として Kotlin 1.6 をターゲットにしていたためビルドエラーが発生した。

**Problem / Root Cause**:

```
error: language version 1.6 is unsupported. Supported versions: 1.9, 2.0, 2.1, 2.2
```

- `sentry_flutter` 等のプラグインが自身の Gradle 設定に `languageVersion = '1.6'` を持っている
- Kotlin 2.4.0 コンパイラはその設定を受け付けなくなった
- アプリモジュール（`:app`）には `languageVersion` 指定がなく、プラグインの `subprojects` による上書きもなかった

**Solution**:

Fix 1 — `android/app/build.gradle.kts` の `compilerOptions` に `languageVersion = KOTLIN_2_0` を追加:

```kotlin
// ❌ 修正前
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
    }
}

// ✅ 修正後
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
        languageVersion = org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0
    }
}
```

Fix 2 — `android/build.gradle.kts` にすべてのサブプロジェクト（プラグイン含む）に対して `languageVersion = KOTLIN_2_0` を強制する `subprojects` ブロックを追加:

```kotlin
// ✅ 全サブプロジェクトの Kotlin コンパイルタスクに言語バージョンを強制
subprojects {
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
        }
    }
}
```

Fix 3 — ビルド番号を 1.1.0+17 → 1.1.0+18 へインクリメント

**検証結果**: Android ビルドエラー解消を確認（`flutter build apk --debug --flavor prod --dart-define=FLAVOR=prod` 成功）

**Modified Files**:

- `android/app/build.gradle.kts` — `compilerOptions` に `languageVersion = KOTLIN_2_0` を追加
- `android/build.gradle.kts` — 全サブプロジェクト向け `languageVersion` 強制ブロックを追加
- `pubspec.yaml` — `version: 1.1.0+17` → `version: 1.1.0+18`

**Commit**: `49c939d` — `fix: Kotlin language version 1.6 unsupported error (build 18)`
**Status**: ✅ 完了・検証済み

---

## 🐛 発見された問題

### Kotlin 2.4.0 とサードパーティプラグインの互換性問題 ✅

- **症状**: `flutter build apk` 実行時に `error: language version 1.6 is unsupported` が発生
- **原因**: sentry_flutter 等のプラグインが Kotlin 1.6 ターゲットのまま、Kotlin 2.4.0 コンパイラと非互換
- **対処**: ルート `build.gradle.kts` で `subprojects` ブロックを使い全プラグインに言語バージョン 2.0 を強制
- **状態**: 修正完了

---

## 📊 バグ対応進捗

### 完了 ✅

1. ✅ Windows Firebase Auth `unknown-error` 修正（2026-06-24）
2. ✅ QR 招待 Firestore サイレント書き込み失敗修正（2026-06-24）
3. ✅ Kotlin 2.1.0→2.4.0 アップグレード + DSL 移行（2026-06-24）
4. ✅ Kotlin language version 1.6 未サポートエラー修正（2026-06-25）

### 翌日継続 ⏳

- ⏳ Windows QR 招待エンドツーエンドテスト（サインイン安定後に着手）

---

## 💡 技術的学習事項

### Kotlin コンパイラバージョンと言語バージョンの分離

Kotlin では「コンパイラバージョン（ツールチェイン）」と「言語バージョン（コード互換性）」は独立している。
Kotlin 2.4.0 コンパイラは言語バージョン 1.6 のコードをコンパイルできなくなった（1.9, 2.0, 2.1, 2.2 が対象）。

**問題パターン**:

```kotlin
// sentry_flutter 等のプラグイン側（自動）
kotlinOptions {
    languageVersion = '1.6'  // Kotlin 2.4.0 では unsupported
}
```

**正しいパターン**:

```kotlin
// android/build.gradle.kts でプロジェクト全体に強制
subprojects {
    tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
        compilerOptions {
            languageVersion.set(org.jetbrains.kotlin.gradle.dsl.KotlinVersion.KOTLIN_2_0)
        }
    }
}
```

**教訓**: Kotlin をメジャーバージョンアップする際は、サードパーティプラグインの `languageVersion` 設定を確認し、ルート `build.gradle.kts` でバージョンを強制する必要がある。

---

## 🗓 翌日（2026-06-26）の予定

1. Windows QR 招待エンドツーエンドテスト
2. iOS ビルド確認（Kotlin 変更の影響がないことを確認）
3. 必要に応じて sentry_flutter の Kotlin 互換バージョンへのアップグレードを検討

---

## 📝 ドキュメント更新

| ドキュメント                        | 更新内容                                                                                         |
| ----------------------------------- | ------------------------------------------------------------------------------------------------ |
| `instructions/90_testing_and_ci.md` | Kotlin 2.4.0 アップグレード時の languageVersion 強制パターンを「ビルドコマンド」セクションに追記 |
