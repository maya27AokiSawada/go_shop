// Debug script to enable secret mode for TestScenarioWidget
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

void main() async {
  // Flutter初期化は不要な場合があるので、try-catchで囲む
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Flutter初期化完了');
  } catch (e) {
    print('⚠️ Flutter初期化スキップ: $e');
  }

  try {
    final prefs = await SharedPreferences.getInstance();

    // シークレットモードを有効にする
    final success = await prefs.setBool('secret_mode', true);

    if (success) {
      print('✅ シークレットモード有効化成功！');
      print('🧪 TestScenarioWidgetが表示されるようになりました');
    } else {
      print('❌ シークレットモード有効化失敗');
    }

    // 確認
    final currentMode = prefs.getBool('secret_mode') ?? false;
    print('🔍 現在のシークレットモード: $currentMode');
  } catch (e) {
    print('❌ エラー: $e');
  }

  exit(0);
}
