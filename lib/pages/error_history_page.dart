import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/error_log_service.dart';
import '../utils/app_logger.dart';
import '../l10n/l10n.dart';
import '../l10n/app_texts.dart';

/// エラー履歴画面
///
/// ユーザーの操作エラー履歴をSharedPreferencesから取得して表示
/// - 最新20件のみ保存（ローカルストレージ）
/// - エラータイプ別のアイコン・色表示
/// - 時間差表示
/// - 既読管理
/// - 既読エラーの一括削除
class ErrorHistoryPage extends ConsumerStatefulWidget {
  const ErrorHistoryPage({super.key});

  @override
  ConsumerState<ErrorHistoryPage> createState() => _ErrorHistoryPageState();
}

class _ErrorHistoryPageState extends ConsumerState<ErrorHistoryPage> {
  List<Map<String, dynamic>> _errorLogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadErrorLogs();
  }

  /// エラーログを読み込み
  Future<void> _loadErrorLogs() async {
    setState(() => _isLoading = true);

    try {
      final logs = await ErrorLogService.getErrorLogs();
      if (mounted) {
        setState(() {
          _errorLogs = logs;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('エラーログ読み込み失敗: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(texts.errorHistory),
        actions: [
          // 既読エラーの一括削除
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: texts.tooltipDeleteRead,
            onPressed: _deleteReadErrors,
          ),
          // 再読み込み
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: texts.tooltipReload,
            onPressed: _loadErrorLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorLogs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green),
                      const SizedBox(height: 16),
                      Text(texts.noErrorHistory),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: _errorLogs.length,
                  itemBuilder: (context, index) {
                    final errorData = _errorLogs[index];
                    return _buildErrorLogTile(context, index, errorData);
                  },
                ),
    );
  }

  /// エラーログタイルを構築
  Widget _buildErrorLogTile(
    BuildContext context,
    int index,
    Map<String, dynamic> errorData,
  ) {
    final errorType = errorData['errorType'] as String? ?? 'unknown';
    final operationRaw = errorData['operation'] as String? ?? '';
    final operation = _localizeOperationName(operationRaw);
    final message = errorData['message'] as String? ?? texts.noErrorDetailMsg;
    final timestampStr = errorData['timestamp'] as String?;
    final isRead = errorData['read'] as bool? ?? false;

    final timestamp =
        timestampStr != null ? DateTime.tryParse(timestampStr) : null;

    final errorInfo = _getErrorTypeInfo(errorType);
    final timeAgo = _getTimeAgo(timestamp);

    return Card(
      elevation: isRead ? 0 : 2,
      color: isRead ? Colors.grey.shade100 : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(
          errorInfo['icon'] as IconData,
          color: errorInfo['color'] as Color,
          size: 32,
        ),
        title: Text(
          operation,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              timeAgo,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        trailing: isRead
            ? null
            : IconButton(
                icon: const Icon(Icons.check, color: Colors.grey),
                tooltip: texts.tooltipMarkRead,
                onPressed: () => _markAsRead(index),
              ),
        onTap: () => _showErrorDetail(context, errorData, index),
      ),
    );
  }

  /// operationキーをl10n文字列に変換
  String _localizeOperationName(String key) {
    switch (key) {
      case 'サインイン':
        return texts.opSignIn;
      case 'アカウント作成':
        return texts.opCreateAccount;
      case 'ユーザー名保存':
        return texts.opSaveUserName;
      case 'パスワードリセット':
        return texts.opResetPassword;
      case 'サインアップ処理':
        return texts.opSignUp;
      case 'メンバー追加':
        return texts.opAddMember;
      case 'グループ名更新':
        return texts.opUpdateGroupName;
      case 'ホワイトボード保存':
        return texts.opSaveWhiteboard;
      case 'ホワイトボード全消去':
        return texts.opClearWhiteboard;
      case '購入状態更新':
        return texts.opUpdatePurchaseStatus;
      case 'グループメンバー更新':
        return texts.opUpdateGroupMember;
      case '通知送信':
        return texts.opSendNotification;
      case 'ユーザー名読み込み':
        return texts.opLoadUserName;
      case '全グループユーザー名更新':
        return texts.opUpdateAllGroupUserNames;
      case 'グループユーザー名取得':
        return texts.opGetGroupUserName;
      case 'グループメンバー取得':
        return texts.opGetGroupMembers;
      case 'サインアウト時クリア':
        return texts.opSignOutClear;
      case 'Firestoreユーザー名取得':
        return texts.opGetFirestoreUserName;
      case 'Firestoreユーザー名保存':
        return texts.opSaveFirestoreUserName;
      case 'Firestoreユーザー名削除':
        return texts.opDeleteFirestoreUserName;
      case 'ユーザープロフィール作成':
        return texts.opCreateUserProfile;
      case '課金タイプ保存':
        return texts.opSaveBillingType;
      case '招待可能グループ検索':
        return texts.opSearchInvitableGroups;
      case '招待送信':
        return texts.opSendInvite;
      case '招待受諾':
        return texts.opAcceptInvitation;
      case '未受諾招待検索':
        return texts.opSearchPendingInvitations;
      case '招待受諾記録':
        return texts.opRecordInvitation;
      case '未処理招待取得':
        return texts.opGetPendingInvitations;
      case '招待処理済みマーク':
        return texts.opMarkInvitationProcessed;
      case '受諾招待削除':
        return texts.opDeleteInvitation;
      case 'QR招待作成':
        return texts.opCreateQrInvite;
      case 'QRコードデコード':
        return texts.opDecodeQrCode;
      case 'QR招待詳細取得':
        return texts.opGetQrInviteDetails;
      case 'QR招待受諾':
        return texts.opAcceptQrInvite;
      default:
        return key.isEmpty ? texts.unknownOperation : key;
    }
  }

  /// エラータイプ別の情報を取得
  Map<String, dynamic> _getErrorTypeInfo(String errorType) {
    switch (errorType) {
      case 'permission':
        return {
          'icon': Icons.lock,
          'color': Colors.red,
          'label': texts.permissionErrorLabel,
        };
      case 'network':
        return {
          'icon': Icons.wifi_off,
          'color': Colors.orange,
          'label': texts.networkErrorLabel,
        };
      case 'sync':
        return {
          'icon': Icons.sync_problem,
          'color': Colors.purple,
          'label': texts.syncErrorLabel,
        };
      case 'validation':
        return {
          'icon': Icons.warning,
          'color': Colors.amber,
          'label': texts.validationErrorLabel,
        };
      case 'operation':
        return {
          'icon': Icons.error_outline,
          'color': Colors.red.shade700,
          'label': texts.operationErrorLabel,
        };
      default:
        return {
          'icon': Icons.bug_report,
          'color': Colors.grey,
          'label': texts.unknownErrorLabel,
        };
    }
  }

  /// 時間差を計算
  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return texts.timeUnknown;

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return texts.justNow;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${texts.minutesAgo}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${texts.hoursAgo}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${texts.daysAgo}';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  /// エラー詳細を表示
  void _showErrorDetail(
    BuildContext context,
    Map<String, dynamic> errorData,
    int index,
  ) {
    final errorType = errorData['errorType'] as String? ?? 'unknown';
    final operation =
        errorData['operation'] as String? ?? texts.unknownOperation;
    final message = errorData['message'] as String? ?? texts.noErrorDetailMsg;
    final stackTrace = errorData['stackTrace'] as String?;
    final timestampStr = errorData['timestamp'] as String?;
    final contextData = errorData['context'] as Map<String, dynamic>?;

    final timestamp =
        timestampStr != null ? DateTime.tryParse(timestampStr) : null;
    final errorInfo = _getErrorTypeInfo(errorType);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(errorInfo['icon'] as IconData,
                color: errorInfo['color'] as Color),
            const SizedBox(width: 8),
            Expanded(child: Text(errorInfo['label'] as String)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow(texts.operationLabel, operation),
              const SizedBox(height: 8),
              _buildDetailRow(texts.messageLabel, message),
              if (timestamp != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow(texts.occurredAtLabel, timestamp.toString()),
              ],
              if (contextData != null && contextData.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow(texts.contextLabel, contextData.toString()),
              ],
              if (stackTrace != null && stackTrace.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  texts.stackTraceLabel,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    stackTrace,
                    style:
                        const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _markAsRead(index);
              Navigator.pop(context);
            },
            child: Text(texts.markReadAndClose),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(texts.close),
          ),
        ],
      ),
    );
  }

  /// 詳細情報の行を構築
  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  /// エラーを既読にする
  Future<void> _markAsRead(int index) async {
    try {
      await ErrorLogService.markAsRead(index);
      await _loadErrorLogs(); // 再読み込み

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(texts.markedAsRead),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('エラー既読マークエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(texts.markedReadFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 既読エラーを一括削除
  Future<void> _deleteReadErrors() async {
    // 確認ダイアログ
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(texts.deleteReadErrors),
        content: Text(texts.deleteReadErrorsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(texts.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(texts.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final deletedCount = await ErrorLogService.deleteReadLogs();
      await _loadErrorLogs(); // 再読み込み

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(texts.deletedErrorLogs(deletedCount)),
            backgroundColor: Colors.green,
          ),
        );
      }

      AppLogger.info('✅ 既読エラーログ削除完了: $deletedCount件');
    } catch (e) {
      AppLogger.error('既読エラー削除エラー: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(texts.deleteErrorLogFailed(e.toString())),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
