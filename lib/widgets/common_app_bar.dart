import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import '../models/shared_group.dart';
import '../pages/notification_history_page.dart';
import '../pages/error_history_page.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 同期状態の種類
enum SyncState {
  synced, // 同期完了
  syncing, // 同期中
  offline, // オフライン/接続断
  notLoggedIn, // 未ログイン
}

/// 共通AppBar
/// - 同期状態アイコン
/// - フローティングメニューボタン（ヘルプ、バージョン情報）
/// - ページごとのタイトル表示（ユーザー名、グループ名など）
class CommonAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final SyncState syncState;
  final SharedGroup? currentGroup;
  final bool showUserName;
  final bool showGroupName;

  const CommonAppBar({
    super.key,
    this.title,
    this.syncState = SyncState.notLoggedIn,
    this.currentGroup,
    this.showUserName = false,
    this.showGroupName = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return AppBar(
      title: FutureBuilder<String>(
        future: _buildTitle(authState.value),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Text(snapshot.data!);
          }
          return Text(title ?? 'GoShopping');
        },
      ),
      actions: [
        // 同期状態アイコン
        _buildSyncStatusIcon(context, authState.value),
        const SizedBox(width: 8),

        // フローティングメニューボタン
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'notifications':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NotificationHistoryPage(),
                  ),
                );
                break;
              case 'errors':
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ErrorHistoryPage(),
                  ),
                );
                break;
              case 'help':
                _showHelpDialog(context);
                break;
              case 'version':
                _showVersionDialog(context);
                break;
            }
          },
          itemBuilder: (context) => [
            // 通知履歴（認証済みの場合のみ表示）
            if (authState.value != null)
              const PopupMenuItem(
                value: 'notifications',
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('通知履歴'),
                  ],
                ),
              ),
            // エラー履歴（認証済みの場合のみ表示）
            if (authState.value != null)
              const PopupMenuItem(
                value: 'errors',
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('エラー履歴'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  Icon(Icons.help_outline, size: 20),
                  SizedBox(width: 8),
                  Text('ヘルプ'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'version',
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20),
                  SizedBox(width: 8),
                  Text('バージョン情報'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// タイトルを構築
  Future<String> _buildTitle(user) async {
    // ユーザー名表示（ホーム画面）
    if (showUserName) {
      // 未認証の場合は「未サインイン」を表示
      if (user == null) {
        return '未サインイン';
      }

      final userName = await UserPreferencesService.getUserName();
      if (userName != null && userName.isNotEmpty) {
        return '$userName さん';
      }
      return 'ホーム';
    }

    // グループ名表示（グループ画面・リスト画面）
    if (showGroupName && currentGroup != null) {
      return currentGroup!.groupName;
    }

    // デフォルトタイトル
    return title ?? 'GoShopping';
  }

  /// 同期状態アイコンを構築
  Widget _buildSyncStatusIcon(BuildContext context, user) {
    IconData icon;
    Color color;
    String tooltip;

    switch (syncState) {
      case SyncState.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = '同期完了';
        break;
      case SyncState.syncing:
        icon = Icons.sync;
        color = Colors.orange;
        tooltip = '同期中...';
        break;
      case SyncState.offline:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = '接続断';
        break;
      case SyncState.notLoggedIn:
        icon = Icons.account_circle_outlined;
        color = Colors.grey;
        tooltip = '未ログイン';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Icon(
        icon,
        color: color,
        size: 24,
      ),
    );
  }

  /// ヘルプダイアログを表示
  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('ヘルプ'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHelpSection(
                '基本的な使い方',
                [
                  'グループを作成して、メンバーを招待できます',
                  '買い物リストを共有して、リアルタイムで同期します',
                  'アイテムを追加・購入完了マークで管理できます',
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                'グループ招待',
                [
                  'QRコードを表示してメンバーを招待',
                  'QRコードをスキャンしてグループに参加',
                  '招待は24時間有効、最大5名まで',
                ],
              ),
              const SizedBox(height: 16),
              _buildHelpSection(
                '同期状態アイコン',
                [
                  '🟢 緑: 同期完了',
                  '🟠 オレンジ: 同期中',
                  '🔴 赤: 接続断',
                  '⚪ グレー: 未ログイン',
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  /// ヘルプセクションを構築
  Widget _buildHelpSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• '),
                  Expanded(child: Text(item)),
                ],
              ),
            )),
      ],
    );
  }

  /// バージョン情報ダイアログを表示
  void _showVersionDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('バージョン情報'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GoShopping',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildVersionRow('バージョン', packageInfo.version),
              _buildVersionRow('ビルド番号', packageInfo.buildNumber),
              _buildVersionRow('パッケージ名', packageInfo.packageName),
              const SizedBox(height: 16),
              const Text(
                '買い物リスト共有アプリ',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                '© 2025 GoShopping Team',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );
    }
  }

  /// バージョン情報の行を構築
  Widget _buildVersionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
