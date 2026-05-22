import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shared_group_provider.dart';
import '../../services/user_preferences_service.dart';
import '../../utils/app_logger.dart';
import '../../config/app_mode_config.dart';
import '../../l10n/l10n.dart';

/// アカウント削除セクション（認証済みユーザー向け）
class AccountDeletionSection extends ConsumerStatefulWidget {
  final User user;
  const AccountDeletionSection({super.key, required this.user});

  @override
  ConsumerState<AccountDeletionSection> createState() =>
      _AccountDeletionSectionState();
}

class _AccountDeletionSectionState
    extends ConsumerState<AccountDeletionSection> {
  /// 再認証ダイアログ（パスワード入力）
  Future<String?> _showReauthDialog() async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;

    return await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.lock, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  texts.reauthRequired,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texts.reauthDescription,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: texts.password,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) {
                      final password = passwordController.text.trim();
                      if (password.isNotEmpty) {
                        Navigator.of(context).pop(password);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text(texts.cancel),
            ),
            ElevatedButton(
              onPressed: () {
                final password = passwordController.text.trim();
                if (password.isEmpty) {
                  return;
                }
                Navigator.of(context).pop(password);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text(texts.confirm),
            ),
          ],
        ),
      ),
    );
  }

  /// アカウント削除メソッド
  Future<void> _deleteAccount() async {
    final user = widget.user;
    BuildContext? spinnerDialogContext;

    try {
      // 確認ダイアログ（ステップ1: 警告）
      final confirm1 = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.warning, color: Colors.red, size: 32),
              const SizedBox(width: 12),
              Text(texts.deleteAccount),
            ],
          ),
          content: Text(
            texts.deleteAccountWarningBody(AppModeSettings.config.sharedList),
            style: const TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(texts.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(texts.delete),
            ),
          ],
        ),
      );

      if (confirm1 != true) return;

      // 確認ダイアログ（ステップ2: 最終確認）
      if (!mounted) return;
      final confirm2 = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(texts.finalConfirmation),
          content: Text(
            texts.finalConfirmationBody(user.email ?? ''),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(texts.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(texts.deleteCompletely),
            ),
          ],
        ),
      );

      if (confirm2 != true) return;

      // ステップ3: 再認証（Firestoreデータ削除前に完了させる）
      if (!mounted) return;
      final password = await _showReauthDialog();
      if (password == null || password.isEmpty) return;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      try {
        await user.reauthenticateWithCredential(credential);
        AppLogger.info('✅ [DELETE_ACCOUNT] 再認証成功');
      } on FirebaseAuthException catch (e) {
        AppLogger.error('❌ [DELETE_ACCOUNT] 再認証失敗: ${e.code}');
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Text(texts.authError),
              ],
            ),
            content: Text(
              e.code == 'wrong-password'
                  ? texts.wrongPassword
                  : '${texts.authFailed}\n\n${texts.error}: ${e.message}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(texts.close),
              ),
            ],
          ),
        );
        return;
      }

      // ローディング表示
      if (!mounted) return;
      // user.delete() 後に authStateProvider が変化し widget が unmount される場合があるため
      // mounted チェックを実施してから context を使用する
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          spinnerDialogContext = dialogContext;
          return Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(texts.deletingAccount),
                    const SizedBox(height: 8),
                    Text(
                      texts.deletingAccountProgress,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      AppLogger.info(
          '🗑️ [DELETE_ACCOUNT] アカウント削除開始: ${AppLogger.maskUserId(user.uid)}');

      final firestore = FirebaseFirestore.instance;

      // === Batch 1: サブコレクション削除（先に実行） ===
      final batch1 = firestore.batch();
      int subCollectionCount = 0;

      final ownerGroups = await firestore
          .collection('SharedGroups')
          .where('ownerUid', isEqualTo: user.uid)
          .get();

      AppLogger.info(
          '📝 [DELETE_ACCOUNT] オーナーグループ数: ${ownerGroups.docs.length}');

      for (var doc in ownerGroups.docs) {
        final lists = await doc.reference.collection('sharedLists').get();
        for (var listDoc in lists.docs) {
          batch1.delete(listDoc.reference);
          subCollectionCount++;
        }
        AppLogger.info(
            '📝 [DELETE_ACCOUNT] グループ ${AppLogger.maskGroupId(doc.id, currentUserId: user.uid)} のリスト削除: ${lists.docs.length}件');

        final whiteboards = await doc.reference.collection('whiteboards').get();
        for (var wbDoc in whiteboards.docs) {
          batch1.delete(wbDoc.reference);
          subCollectionCount++;
        }
        AppLogger.info(
            '📝 [DELETE_ACCOUNT] グループ ${AppLogger.maskGroupId(doc.id, currentUserId: user.uid)} のホワイトボード削除: ${whiteboards.docs.length}件');
      }

      if (subCollectionCount > 0) {
        await batch1.commit();
        AppLogger.info('✅ [DELETE_ACCOUNT] サブコレクション削除完了（$subCollectionCount件）');
      }

      // === Batch 2: 親グループ + メンバー離脱 + 通知 + 招待 + ユーザープロファイル ===
      final batch2 = firestore.batch();

      for (var doc in ownerGroups.docs) {
        batch2.delete(doc.reference);
        AppLogger.info(
            '📝 [DELETE_ACCOUNT] オーナーグループ削除予約: ${AppLogger.maskGroupId(doc.id, currentUserId: user.uid)}');
      }

      final memberGroups = await firestore
          .collection('SharedGroups')
          .where('allowedUid', arrayContains: user.uid)
          .get();

      int leaveGroupCount = 0;
      for (var doc in memberGroups.docs) {
        final data = doc.data();
        if (data['ownerUid'] != user.uid) {
          batch2.update(doc.reference, {
            'allowedUid': FieldValue.arrayRemove([user.uid]),
            'members': FieldValue.arrayRemove([
              {
                'memberId': user.uid,
              }
            ]),
          });
          leaveGroupCount++;
          AppLogger.info(
              '📝 [DELETE_ACCOUNT] グループ離脱予約: ${AppLogger.maskGroupId(doc.id, currentUserId: user.uid)}');
        }
      }
      AppLogger.info('📝 [DELETE_ACCOUNT] メンバーグループ離脱数: $leaveGroupCount');

      final notifications = await firestore
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .get();

      AppLogger.info('📝 [DELETE_ACCOUNT] 通知数: ${notifications.docs.length}');

      for (var doc in notifications.docs) {
        batch2.delete(doc.reference);
      }

      // ※ /invitations コレクション（レガシー）はセキュリティルールで全拒否のため
      // クエリ不可。v3.x 以降は SharedGroups サブコレクションに移行済みのためスキップ。

      final userDoc = firestore.collection('users').doc(user.uid);
      batch2.delete(userDoc);
      AppLogger.info('📝 [DELETE_ACCOUNT] ユーザープロファイル削除予約（最後）');

      await batch2.commit();
      AppLogger.info('✅ [DELETE_ACCOUNT] Firestoreデータ削除完了');

      // 2. Hiveデータ削除
      final boxSuffix = user.uid;
      final sharedGroupBoxName = 'SharedGroups_$boxSuffix';
      final sharedListBoxName = 'SharedLists_$boxSuffix';

      if (Hive.isBoxOpen(sharedGroupBoxName)) {
        await Hive.box(sharedGroupBoxName).close();
      }
      await Hive.deleteBoxFromDisk(sharedGroupBoxName);

      if (Hive.isBoxOpen(sharedListBoxName)) {
        await Hive.box(sharedListBoxName).close();
      }
      await Hive.deleteBoxFromDisk(sharedListBoxName);

      AppLogger.info('✅ [DELETE_ACCOUNT] Hiveデータ削除完了');

      // 3. SharedPreferences削除
      await UserPreferencesService.clearAllUserInfo();
      AppLogger.info('✅ [DELETE_ACCOUNT] SharedPreferences削除完了');

      // 4. Firebase Authアカウント削除（再認証済みのため requires-recent-login は発生しない）
      await user.delete();
      AppLogger.info('✅ [DELETE_ACCOUNT] Firebase Authアカウント削除完了');

      // 5. Provider無効化
      ref.invalidate(authStateProvider);
      ref.invalidate(allGroupsProvider);
      ref.invalidate(selectedGroupIdProvider);

      // ローディングダイアログを閉じる
      try {
        if (spinnerDialogContext?.mounted ?? false) {
          AppLogger.info('✅ [DELETE_ACCOUNT] スピナーダイアログをクローズします');
          Navigator.of(spinnerDialogContext!).pop();
          AppLogger.info('✅ [DELETE_ACCOUNT] スピナーダイアログクローズ完了');
        }
      } catch (e) {
        AppLogger.error('⚠️ [DELETE_ACCOUNT] スピナーダイアログ閉じに失敗: $e');
      }

      // 完了ダイアログ表示
      try {
        if (!mounted) {
          AppLogger.info('⚠️ [DELETE_ACCOUNT] Widget がアンマウント済み。完了ダイアログ非表示');
          return;
        }

        AppLogger.info('✅ [DELETE_ACCOUNT] 完了ダイアログを表示します');
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text(texts.deletionComplete),
              ],
            ),
            content: Text(texts.deletionCompleteBody),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(texts.ok),
              ),
            ],
          ),
        );
      } catch (e) {
        AppLogger.error('⚠️ [DELETE_ACCOUNT] 完了ダイアログ表示に失敗: $e');
      }
    } catch (e, stack) {
      AppLogger.error('❌ [DELETE_ACCOUNT] エラー', e, stack);

      // スピナーダイアログを閉じる
      try {
        if (spinnerDialogContext?.mounted ?? false) {
          AppLogger.info('❌ [DELETE_ACCOUNT] エラー中: スピナーをクローズしています');
          Navigator.of(spinnerDialogContext!).pop();
        }
      } catch (closeError) {
        AppLogger.error('⚠️ [DELETE_ACCOUNT] スピナー閉じエラー: $closeError');
      }

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text(texts.deletionFailed),
            ],
          ),
          content: Text(texts.deletionFailedBody(e.toString())),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(texts.close),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: Colors.red.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.delete_forever, color: Colors.red.shade700),
                const SizedBox(width: 8),
                Text(
                  texts.deleteAccount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              texts.deleteAccountAndData,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              texts.cannotUndoWarning,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await _deleteAccount();
                },
                icon: const Icon(Icons.delete_forever, size: 18),
                label: Text(texts.deleteAccount),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
