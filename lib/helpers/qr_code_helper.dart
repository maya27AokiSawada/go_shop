import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../helpers/auth_state_helper.dart';
import '../helpers/ui_helper.dart';
import '../providers/auth_provider.dart';

final logger = Logger();

/// QRコード関連の処理を集約するヘルパークラス（簡素化版）
/// 
/// 設計方針：サインアップ前はQRコード機能を制限し、
/// Firebase UIDが確定してから招待機能を有効化する
class QrCodeHelper {
  
  /// QRコードスキャンを開始（認証チェック付き）
  static void handleQrCodeScan(BuildContext context, WidgetRef ref, VoidCallback onShowSignUp) {
    final user = ref.read(authProvider).currentUser;
    
    // サインアップ前は機能を制限
    if (!AuthStateHelper.canUseQrCodeFeatures(user)) {
      AuthStateHelper.showSignUpPrompt(context, onShowSignUp);
      return;
    }
    
    // 認証済みユーザーのみQRスキャンを実行
    logger.i('🔍 QRコードスキャン開始 (認証済み)');
    UiHelper.showInfoMessage(context, 'QRコード機能は開発中です', duration: const Duration(seconds: 2));
  }

  /// 保留中の招待を処理（認証済みのみ実行）
  /// 
  /// サインアップ前はFirebase UIDが無いため招待処理は実行しない
  /// 複雑な一時保存処理を削除し、認証後のみ招待を処理する
  static Future<void> processPendingInvitation(BuildContext context, WidgetRef ref, VoidCallback onSuccess) async {
    final user = ref.read(authProvider).currentUser;
    
    // サインアップ前は処理不要（Firebase UIDが必要）
    if (!AuthStateHelper.canUseQrCodeFeatures(user)) {
      logger.i('⏸️ 未認証のため招待処理をスキップ');
      return;
    }
    
    // 認証済みユーザーのみ処理を実行
    logger.i('🔄 保留中の招待処理を確認中...');
    // TODO: 実際の招待処理実装（Firebase UIDベースの招待のみ）
    onSuccess();
  }

  /// QRコード招待ボタンを認証状態に応じて構築
  static Widget buildQrScanButton({
    required BuildContext context,
    required WidgetRef ref,
    required VoidCallback onShowSignUp,
  }) {
    final user = ref.read(authProvider).currentUser;
    
    return AuthStateHelper.buildQrScanButton(
      user: user,
      onScan: () => handleQrCodeScan(context, ref, onShowSignUp),
      onSignUpPrompt: () => AuthStateHelper.showSignUpPrompt(context, onShowSignUp),
    );
  }
}
