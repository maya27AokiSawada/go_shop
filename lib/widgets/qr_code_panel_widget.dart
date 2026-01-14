import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../widgets/qr_invitation_widgets.dart';

/// QRコード招待・受諾パネルウィジェット
class QRCodePanelWidget extends ConsumerStatefulWidget {
  /// サインインフォーム表示のコールバック
  final VoidCallback? onShowSignInForm;

  /// QRコード処理成功時のコールバック
  final VoidCallback? onQRSuccess;

  const QRCodePanelWidget({
    super.key,
    this.onShowSignInForm,
    this.onQRSuccess,
  });

  @override
  ConsumerState<QRCodePanelWidget> createState() => _QRCodePanelWidgetState();
}

class _QRCodePanelWidgetState extends ConsumerState<QRCodePanelWidget> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.qr_code_2, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  '🔗 QRコード招待システム',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'QRコードで簡単にグループ招待・参加',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // 認証済みユーザー向けの機能
            authState.when(
              data: (user) {
                if (user != null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        '🎯 グループ招待（認証済みユーザー向け）',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),

                      // QRコード招待ボタン（サンプル用）
                      QRInviteButton(
                        sharedListId: 'sample_list_id',
                        sharedGroupId: 'sample_group_id',
                        groupName: 'サンプルグループ',
                        groupOwnerUid: user.uid,
                        groupAllowedUids: [user.uid],
                        customMessage: 'GoShoppingグループへようこそ！',
                      ),

                      const SizedBox(height: 8),

                      // QRコード読み取りボタン（再配置）
                      const QRScanButton(),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.orange, size: 20),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'グループ招待機能を使用するにはログインが必要です',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.orange),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
              loading: () => const SizedBox(
                height: 20,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, stack) => Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'エラー: $err',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
