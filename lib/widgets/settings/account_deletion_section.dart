import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/shared_group_provider.dart';
import '../../services/user_preferences_service.dart';
import '../../utils/app_logger.dart';

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
          title: const Row(
            children: [
              Icon(Icons.lock, color: Colors.orange),
              SizedBox(width: 8),
              Text('再認証が必要です'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'セキュリティのため、パスワードを再入力してください。',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'パスワード',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscurePassword ? Icons.visibility : Icons.visibility_off,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('キャンセル'),
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
              child: const Text('確認'),
            ),
          ],
        ),
      ),
    );
  }

  /// アカウント削除メソッド
  Future<void> _deleteAccount() async {
    final user = widget.user;
    try {
      // 確認ダイアログ（ステップ1: 警告）
      final confirm1 = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text('アカウント削除'),
            ],
          ),
          content: const Text(
            '⚠️ この操作は取り消せません\n\n'
            '以下のデータが完全に削除されます:\n'
            '• アカウント情報\n'
            '• 全ての買い物リスト\n'
            '• 作成したグループ（オーナーの場合）\n'
            '• ホワイトボードデータ\n'
            '• 通知履歴\n\n'
            '本当に削除しますか？',
            style: TextStyle(fontSize: 15),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('削除する'),
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
          title: const Text('最終確認'),
          content: Text(
            'メールアドレス: ${user.email}\n\n'
            'このアカウントを本当に削除しますか？\n\n'
            'この操作は取り消せません。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('完全に削除'),
            ),
          ],
        ),
      );

      if (confirm2 != true) return;

      // ローディング表示
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('アカウントを削除中...'),
                  SizedBox(height: 8),
                  Text(
                    'データ削除 → 認証削除',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
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

      final invitations = await firestore
          .collection('invitations')
          .where('invitedBy', isEqualTo: user.uid)
          .get();

      AppLogger.info('📝 [DELETE_ACCOUNT] 招待数: ${invitations.docs.length}');

      for (var doc in invitations.docs) {
        batch2.delete(doc.reference);
      }

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

      // 4. Firebase Authアカウント削除
      try {
        await user.delete();
        AppLogger.info('✅ [DELETE_ACCOUNT] Firebase Authアカウント削除完了');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          AppLogger.warning('⚠️ [DELETE_ACCOUNT] 再認証が必要です');

          if (!mounted) return;
          Navigator.of(context).pop();

          final password = await _showReauthDialog();
          if (password == null || password.isEmpty) {
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('キャンセルされました'),
                content: const Text('アカウント削除をキャンセルしました。'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }

          final credential = EmailAuthProvider.credential(
            email: user.email!,
            password: password,
          );

          try {
            await user.reauthenticateWithCredential(credential);
            AppLogger.info('✅ [DELETE_ACCOUNT] 再認証成功');

            if (!mounted) return;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            await user.delete();
            AppLogger.info('✅ [DELETE_ACCOUNT] Firebase Authアカウント削除完了（再認証後）');
          } on FirebaseAuthException catch (e) {
            if (mounted) Navigator.of(context).pop();

            AppLogger.error('❌ [DELETE_ACCOUNT] 再認証失敗: ${e.code}');

            if (!mounted) return;
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text('認証エラー'),
                  ],
                ),
                content: Text(
                  e.code == 'wrong-password'
                      ? 'パスワードが正しくありません。'
                      : '認証に失敗しました。\n\nエラー: ${e.message}',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('閉じる'),
                  ),
                ],
              ),
            );
            return;
          }
        } else {
          rethrow;
        }
      }

      // 5. Provider無効化
      ref.invalidate(authStateProvider);
      ref.invalidate(allGroupsProvider);
      ref.invalidate(selectedGroupIdProvider);

      if (!mounted) return;
      Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('削除完了'),
            ],
          ),
          content: const Text(
            'アカウントとすべてのデータを削除しました。\n\n'
            'Go Shopをご利用いただきありがとうございました。',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e, stack) {
      AppLogger.error('❌ [DELETE_ACCOUNT] エラー', e, stack);

      if (mounted) Navigator.of(context).pop();

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('削除失敗'),
            ],
          ),
          content: Text(
            'アカウント削除中にエラーが発生しました。\n\n'
            'エラー内容:\n$e\n\n'
            'お手数ですが、開発者にお問い合わせください。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
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
                  'アカウント削除',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'アカウントと全てのデータを完全に削除します',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '⚠️ この操作は取り消せません',
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
                label: const Text('アカウントを削除'),
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
