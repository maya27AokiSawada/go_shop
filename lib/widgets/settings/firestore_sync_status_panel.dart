import 'package:flutter/material.dart';

/// Firestore同期状態を表示するパネルウィジェット
class FirestoreSyncStatusPanel extends StatelessWidget {
  final String syncStatus;

  const FirestoreSyncStatusPanel({
    super.key,
    required this.syncStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (syncStatus == 'idle') {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: syncStatus == 'syncing'
            ? Colors.orange.shade50
            : syncStatus == 'completed'
                ? Colors.green.shade50
                : Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: syncStatus == 'syncing'
              ? Colors.orange.shade200
              : syncStatus == 'completed'
                  ? Colors.green.shade200
                  : Colors.red.shade200,
        ),
      ),
      child: Row(
        children: [
          Icon(
            syncStatus == 'syncing'
                ? Icons.sync
                : syncStatus == 'completed'
                    ? Icons.check_circle
                    : Icons.error,
            color: syncStatus == 'syncing'
                ? Colors.orange
                : syncStatus == 'completed'
                    ? Colors.green
                    : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              syncStatus == 'syncing'
                  ? 'Firestore同期中...'
                  : syncStatus == 'completed'
                      ? 'Firestore同期完了'
                      : 'Firestore同期エラー',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: syncStatus == 'syncing'
                    ? Colors.orange.shade800
                    : syncStatus == 'completed'
                        ? Colors.green.shade800
                        : Colors.red.shade800,
              ),
            ),
          ),
          if (syncStatus == 'syncing')
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}
