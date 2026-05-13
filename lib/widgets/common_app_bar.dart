import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/user_preferences_service.dart';
import '../models/shared_group.dart';
import '../pages/notification_history_page.dart';
import '../pages/error_history_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../config/app_mode_config.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../services/network_monitor_service.dart';

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
    final networkStatus = ref.watch(networkStatusStreamProvider).valueOrNull;

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
        _buildSyncStatusIcon(context, authState.value, networkStatus),
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
              PopupMenuItem(
                value: 'notifications',
                child: Row(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(texts.notificationHistory),
                  ],
                ),
              ),
            // エラー履歴（認証済みの場合のみ表示）
            if (authState.value != null)
              PopupMenuItem(
                value: 'errors',
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(texts.errorHistory),
                  ],
                ),
              ),
            PopupMenuItem(
              value: 'help',
              child: Row(
                children: [
                  const Icon(Icons.help_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(texts.help),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'version',
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 20),
                  const SizedBox(width: 8),
                  Text(texts.versionInfo),
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
        return texts.notSignedIn;
      }

      final userName = await UserPreferencesService.getUserName();
      if (userName != null && userName.isNotEmpty) {
        return '$userName さん';
      }
      return texts.home;
    }

    // グループ名表示（グループ画面・リスト画面）
    if (showGroupName && currentGroup != null) {
      return currentGroup!.groupName;
    }

    // デフォルトタイトル
    return title ?? 'GoShopping';
  }

  /// 同期状態アイコンを構築
  Widget _buildSyncStatusIcon(
      BuildContext context, user, NetworkStatus? networkStatus) {
    // ネットワーク状態を優先して上書き
    if (networkStatus == NetworkStatus.offline) {
      return Tooltip(
        message: texts.networkOfflineStatus,
        child: const Icon(Icons.wifi_off, color: Colors.orange, size: 24),
      );
    }
    if (networkStatus == NetworkStatus.checking) {
      return Tooltip(
        message: texts.checkingConnectionStatus,
        child: const Icon(Icons.wifi_tethering, color: Colors.blue, size: 24),
      );
    }

    IconData icon;
    Color color;
    String tooltip;

    switch (syncState) {
      case SyncState.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = texts.syncStatusSynced;
        break;
      case SyncState.syncing:
        icon = Icons.sync;
        color = Colors.orange;
        tooltip = texts.syncStatusSyncing;
        break;
      case SyncState.offline:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = texts.syncStatusOffline;
        break;
      case SyncState.notLoggedIn:
        icon = Icons.account_circle_outlined;
        color = Colors.grey;
        tooltip = texts.syncStatusNotLoggedIn;
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
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.blue),
            const SizedBox(width: 8),
            Text(texts.helpTitle),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHelpSection(
                  texts.helpBasicUsage,
                  [
                    texts.helpBasicUsagePoint(1),
                    texts.helpBasicUsagePoint(2),
                    texts.helpBasicUsagePoint(3),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpSection(
                  texts.helpGroupInvite,
                  [
                    texts.helpGroupInvitePoint(1),
                    texts.helpGroupInvitePoint(2),
                    texts.helpGroupInvitePoint(3),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpSection(
                  texts.helpSyncIcons,
                  [
                    texts.helpSyncIconPoint(1),
                    texts.helpSyncIconPoint(2),
                    texts.helpSyncIconPoint(3),
                    texts.helpSyncIconPoint(4),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                _buildLegalLinksSection(context),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(texts.close),
          ),
        ],
      ),
    );
  }

  /// 法的リンクセクションを構築
  Widget _buildLegalLinksSection(BuildContext context) {
    final isEn = AppLocalizations.currentLanguageCode == 'en';
    final links = isEn
        ? [
            (
              icon: Icons.privacy_tip_outlined,
              label: texts.privacyPolicy,
              url:
                  'https://maya27aokisawada.github.io/go_shop/specifications/privacy_policy#english-version',
            ),
            (
              icon: Icons.description_outlined,
              label: texts.termsOfService,
              url:
                  'https://maya27aokisawada.github.io/go_shop/specifications/terms_of_service#english-version',
            ),
            (
              icon: Icons.delete_outline,
              label: texts.deleteAccountAndData,
              url:
                  'https://maya27aokisawada.github.io/go_shop/specifications/data_deletion#english',
            ),
          ]
        : [
            (
              icon: Icons.privacy_tip_outlined,
              label: texts.privacyPolicy,
              url:
                  'https://maya27aokisawada.github.io/go_shop/specifications/privacy_policy',
            ),
            (
              icon: Icons.description_outlined,
              label: texts.termsOfService,
              url:
                  'https://maya27aokisawada.github.io/go_shop/specifications/terms_of_service',
            ),
            (
              icon: Icons.delete_outline,
              label: texts.deleteAccountAndData,
              url:
                  'https://maya27aokisawada.github.io/go_shop/specifications/data_deletion',
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          texts.legalTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ...links.map(
          (link) => InkWell(
            onTap: () async {
              final uri = Uri.parse(link.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Row(
                children: [
                  Icon(link.icon, size: 18, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      link.label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Icon(Icons.open_in_new,
                      size: 14, color: Colors.blue.shade400),
                ],
              ),
            ),
          ),
        ),
      ],
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
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 8),
              Text(texts.versionInfoTitle),
            ],
          ),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
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
                  _buildVersionRow(texts.versionLabel, packageInfo.version),
                  _buildVersionRow(
                      texts.buildNumberLabel, packageInfo.buildNumber),
                  _buildVersionRow(
                      texts.packageNameLabel, packageInfo.packageName),
                  const SizedBox(height: 16),
                  Text(
                    '${texts.sharedListNameForMode(AppModeSettings.currentMode == AppMode.shopping)} ${texts.appFooterSubtitle}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '© 2025 GoShopping Team',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(texts.close),
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
