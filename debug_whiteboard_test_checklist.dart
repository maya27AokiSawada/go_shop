/// ホワイトボード機能の実機テストチェックリスト
///
/// 目的: スマホ（縦横）およびタブレット環境での動作確認
///
/// テスト環境:
/// - デバイス1: SH 54D (スマホ縦画面)
/// - デバイス2: Aiwa タブレット (縦横両対応)
/// - デバイス3: Pixel 9 (スマホ縦画面)
///
/// 使用方法:
/// 1. 本ファイルをコピーしてテストしながら、チェックボックスを埋める
/// 2. 各テストカテゴリーで失敗があればスクリーンショット撮影
/// 3. 最後に問題点をまとめてコミットメッセージに含める

class WhiteboardTestChecklist {
  static final testItems = {
    '1. UI表示（スマホ縦画面 - SH54D）': {
      '- ツールバー（上段：色選択）': false,
      '- ツールバー（下段：太さ・ズーム・消去）': false,
      '- グリッド線が全体に表示される': false,
      '- キャンバスが正しいアスペクト比（16:9）': false,
    },
    '2. UI表示（スマホ縦画面 - Pixel9）': {
      '- 全ツールバーアイコンが表示される': false,
      '- オーバーフローなし': false,
      '- グリッドサイズが適切': false,
    },
    '3. UI表示（タブレット - Aiwa）': {
      '- 横画面で全機能が表示される': false,
      '- 大画面用の最大高さ200px制限が機能': false,
      '- プレビューのアスペクト比が正しい': false,
    },
    '4. 描画機能': {
      '- 黒線描画が可能': false,
      '- 赤・緑・黄色描画が可能': false,
      '- カスタム色5が設定値で表示される': false,
      '- カスタム色6が設定値で表示される': false,
      '- 複数色での描画が可能（色切り替え）': false,
      '- 線が正しく保存される': false,
    },
    '5. ペン太さ機能': {
      '- 太さ1.0での描画': false,
      '- 太さ2.0での描画': false,
      '- 太さ4.0での描画': false,
      '- 太さ6.0での描画': false,
      '- 太さ8.0での描画': false,
      '- 太さ変更後の描画が正しく保存': false,
    },
    '6. ズーム機能': {
      '- 1.0倍（デフォルト）での描画': false,
      '- 0.5倍での描画・表示': false,
      '- 1.5倍での描画・表示': false,
      '- 2.0倍での描画・表示': false,
      '- 2.5倍での描画・表示': false,
      '- 3.0倍での描画・表示': false,
      '- 4.0倍での描画・表示': false,
      '- ズーム時の座標変換が正しい': false,
      '- スクロール範囲がズームに応じて拡大': false,
    },
    '7. 消去機能': {
      '- ゴミ箱アイコンが常時表示': false,
      '- クリックでキャンバス全消去': false,
      '- 消去確認ダイアログが表示': false,
      '- 消去後、新規描画が可能': false,
    },
    '8. スクロール・パン機能': {
      '- ズーム時に水平スクロール可能': false,
      '- ズーム時に垂直スクロール可能': false,
      '- スクロール位置が保持される': false,
      '- 描画モード切替時の切り替え': false,
    },
    '9. グリッド表示': {
      '- グリッド線が正しく表示される': false,
      '- グリッドサイズがズームに応じて変更': false,
      '- グリッドが背面に表示（描画より後ろ）': false,
    },
    '10. マルチデバイス同期': {
      '- SH54Dで描画→Pixel9で同期': false,
      '- Pixel9で描画→SH54Dで同期': false,
      '- 色・太さも正しく同期': false,
      '- 別ユーザーの描画も表示': false,
    },
    '11. パフォーマンス': {
      '- 描画が遅延なく表示': false,
      '- ズーム時のフレームレート安定': false,
      '- 大量描画後も動作が遅くならない': false,
      '- メモリリークなし（デバイス長時間動作確認）': false,
    },
    '12. エラーハンドリング': {
      '- ネットワーク切断時の動作': false,
      '- Firestore保存失敗時の動作': false,
      '- スクリーンショット中のクラッシュなし': false,
      '- 戻るボタンでの遷移がスムーズ': false,
    },
    '13. 特殊なシナリオ': {
      '- 描画中のアプリ終了・再起動': false,
      '- ホーム画面→戻ってくる': false,
      '- 複数タブで同時に開く（Web）': false,
      '- オフラインで描画→オンライン復帰': false,
    },
  };

  static void printChecklist() {
    print('═══════════════════════════════════════════════════════════════');
    print('ホワイトボード実機テストチェックリスト');
    print('═══════════════════════════════════════════════════════════════');
    print('');

    testItems.forEach((category, items) {
      print('$category');
      items.forEach((item, status) {
        final checkbox = status ? '✅' : '☐';
        print('  $checkbox $item');
      });
      print('');
    });

    print('═══════════════════════════════════════════════════════════════');
    print('');
  }

  /// テスト結果の統計
  static void printStatistics() {
    int totalTests = 0;
    int passedTests = 0;

    testItems.forEach((_, items) {
      items.forEach((_, status) {
        totalTests++;
        if (status) passedTests++;
      });
    });

    final percentage = (passedTests / totalTests * 100).toStringAsFixed(1);
    print('テスト結果: $passedTests / $totalTests ($percentage%)');
  }
}

// テスト実行ガイド
void main() {
  WhiteboardTestChecklist.printChecklist();
  print('');
  print('【テスト実行手順】');
  print('1. 各デバイスでホワイトボードエディターを開く');
  print('2. 上のチェックリストに従ってテストを実施');
  print('3. 失敗した項目があればスクリーンショット撮影');
  print('4. 失敗事項を `debug_whiteboard_test_result.md` に記録');
  print('5. エディターを閉じて、本チェックリストを更新');
  print('');
  print('【重要なテスト項目（優先度HIGH）】');
  print('- ズーム0.5～4.0での描画・座標変換');
  print('- グリッド表示がキャンバス全体に表示');
  print('- マルチデバイス同期（SH54D↔Pixel9）');
  print('- タブレット（Aiwa）での表示崩れなし');
  print('');
}
