import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/error_log_service.dart';
import '../utils/app_logger.dart';

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
        title: const Text('エラー履歴'),
        actions: [
          // 既読エラーの一括削除
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: '既読エラーを削除',
            onPressed: _deleteReadErrors,
          ),
          // 再読み込み
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '再読み込み',
            onPressed: _loadErrorLogs,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorLogs.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 64, color: Colors.green),
                      SizedBox(height: 16),
                      Text('エラー履歴はありません'),
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
    final operation = errorData['operation'] as String? ?? '不明な操作';
    final message = errorData['message'] as String? ?? 'エラーの詳細なし';
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
                tooltip: '既読にする',
                onPressed: () => _markAsRead(index),
              ),
        onTap: () => _showErrorDetail(context, errorData, index),
      ),
    );
  }

  /// エラータイプ別の情報を取得
  Map<String, dynamic> _getErrorTypeInfo(String errorType) {
    switch (errorType) {
      case 'permission':
        return {
          'icon': Icons.lock,
          'color': Colors.red,
          'label': '権限エラー',
        };
      case 'network':
        return {
          'icon': Icons.wifi_off,
          'color': Colors.orange,
          'label': 'ネットワークエラー',
        };
      case 'sync':
        return {
          'icon': Icons.sync_problem,
          'color': Colors.purple,
          'label': '同期エラー',
        };
      case 'validation':
        return {
          'icon': Icons.warning,
          'color': Colors.amber,
          'label': '入力エラー',
        };
      case 'operation':
        return {
          'icon': Icons.error_outline,
          'color': Colors.red.shade700,
          'label': '操作エラー',
        };
      default:
        return {
          'icon': Icons.bug_report,
          'color': Colors.grey,
          'label': '不明なエラー',
        };
    }
  }

  /// 時間差を計算
  String _getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '時刻不明';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'たった今';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}時間前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}日前';
    } else {
      return '${dateTime.month}月${dateTime.day}日';
    }
  }

  /// エラー詳細を表示
  void _showErrorDetail(
    BuildContext context,
    Map<String, dynamic> errorData,
    int index,
  ) {
    final errorType = errorData['errorType'] as String? ?? 'unknown';
    final operation = errorData['operation'] as String? ?? '不明な操作';
    final message = errorData['message'] as String? ?? 'エラーの詳細なし';
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
              _buildDetailRow('操作', operation),
              const SizedBox(height: 8),
              _buildDetailRow('メッセージ', message),
              if (timestamp != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('発生時刻', timestamp.toString()),
              ],
              if (contextData != null && contextData.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildDetailRow('コンテキスト', contextData.toString()),
              ],
              if (stackTrace != null && stackTrace.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'スタックトレース:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
            child: const Text('既読にして閉じる'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('閉じる'),
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
          const SnackBar(
            content: Text('既読にしました'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      AppLogger.error('エラー既読マークエラー: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('既読にできませんでした: $e'),
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
        title: const Text('既読エラーを削除'),
        content: const Text('既読のエラーログをすべて削除しますか？\nこの操作は元に戻せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
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
            content: Text('$deletedCount件のエラーログを削除しました'),
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
            content: Text('エラーログの削除に失敗しました: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
