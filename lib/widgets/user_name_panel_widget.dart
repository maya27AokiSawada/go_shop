import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_preferences_service.dart';
import '../services/firestore_user_name_service.dart';
import '../providers/user_settings_provider.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';

/// ユーザー名管理パネルウィジェット
class UserNamePanelWidget extends ConsumerStatefulWidget {
  /// ユーザー名コントローラー（親から渡される）
  final TextEditingController userNameController;

  /// 保存成功時のコールバック
  final VoidCallback? onSaveSuccess;

  const UserNamePanelWidget({
    super.key,
    required this.userNameController,
    this.onSaveSuccess,
  });

  @override
  ConsumerState<UserNamePanelWidget> createState() =>
      _UserNamePanelWidgetState();
}

class _UserNamePanelWidgetState extends ConsumerState<UserNamePanelWidget> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.person, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'ユーザー名設定',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'アプリ内で表示されるユーザー名を設定してください',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: widget.userNameController,
                decoration: const InputDecoration(
                  labelText: 'ユーザー名',
                  border: OutlineInputBorder(),
                  hintText: '表示名を入力してください',
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'ユーザー名を入力してください';
                  }
                  if (value.trim().length < 2) {
                    return 'ユーザー名は2文字以上で入力してください';
                  }
                  if (value.trim().length > 20) {
                    return 'ユーザー名は20文字以内で入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _saveUserName,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? '保存中...' : 'ユーザー名を保存'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade800,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // 現在の状態表示（デバッグ用）
              if (widget.userNameController.text.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '現在: ${widget.userNameController.text}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// ユーザー名保存処理
  Future<void> _saveUserName() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userName = widget.userNameController.text.trim();
      AppLogger.info('👤 ユーザー名保存開始: $userName');

      // SharedPreferencesに保存
      final success = await UserPreferencesService.saveUserName(userName);

      if (success) {
        AppLogger.success('✅ ユーザー名保存完了（SharedPreferences）');
      } else {
        throw Exception('SharedPreferencesへの保存に失敗');
      }

      // UserSettings (Hive) にも保存
      try {
        await ref.read(userSettingsProvider.notifier).updateUserName(userName);
        AppLogger.success('✅ ユーザー名保存完了（UserSettings/Hive）');
      } catch (e) {
        AppLogger.warning('⚠️ UserSettings保存エラー: $e');
      }

      // Firestoreにも保存（認証済みの場合）
      if (F.appFlavor == Flavor.prod) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final firestoreSuccess =
              await FirestoreUserNameService.saveUserName(userName);
          if (firestoreSuccess) {
            AppLogger.success('✅ ユーザー名保存完了（Firestore）');
          } else {
            AppLogger.warning('⚠️ Firestoreへの保存に失敗（SharedPreferencesには保存済み）');
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ユーザー名を保存しました'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        widget.onSaveSuccess?.call();
      }
    } catch (e) {
      AppLogger.error('❌ ユーザー名保存エラー: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
