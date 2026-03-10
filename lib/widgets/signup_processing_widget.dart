// lib/widgets/signup_processing_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/app_logger.dart';
import '../models/shared_group.dart';
import '../providers/shared_group_provider.dart';

import '../providers/user_name_provider.dart';
import '../datastore/hybrid_shared_group_repository.dart';
import '../services/user_preferences_service.dart';

/// サインアップ時のデータ移行処理を行うウィジェット
class SignupProcessingWidget extends ConsumerStatefulWidget {
  final User user;
  final String? displayName;
  final VoidCallback? onCompleted;
  final Function(String)? onError;

  const SignupProcessingWidget({
    super.key,
    required this.user,
    this.displayName,
    this.onCompleted,
    this.onError,
  });

  @override
  ConsumerState<SignupProcessingWidget> createState() =>
      _SignupProcessingWidgetState();
}

class _SignupProcessingWidgetState extends ConsumerState<SignupProcessingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isProcessing = false;
  String _currentStep = 'サインアップ処理を開始しています...';
  final List<String> _completedSteps = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // 処理開始
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startSignupProcessing();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// サインアップ処理のメイン実行
  Future<void> _startSignupProcessing() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // STEP1: ユーザー名とメールアドレスの設定
      await _setupUserProfile();
      _addCompletedStep('✅ ユーザープロフィール設定完了');

      // STEP2: ローカルデフォルトグループの検出
      final localDefaultGroup = await _detectLocalDefaultGroup();
      _addCompletedStep('✅ ローカルデータ検出完了');

      // STEP3: Firebase形式のデフォルトグループ作成
      final firebaseGroupId = await _createFirebaseDefaultGroup();
      _addCompletedStep('✅ Firebaseデフォルトグループ作成完了');

      // STEP4: ローカルデータの移行（存在する場合）
      if (localDefaultGroup != null) {
        await _migrateLocalData(localDefaultGroup, firebaseGroupId);
        _addCompletedStep('✅ ローカルデータ移行完了');
      } else {
        _addCompletedStep('💡 移行するローカルデータなし');
      }

      // STEP5: プロバイダーの更新
      await _refreshProviders();
      _addCompletedStep('✅ アプリ状態更新完了');

      // 完了
      setState(() {
        _isProcessing = false;
        _currentStep = 'サインアップ処理が完了しました！';
      });

      // 少し待ってからコールバック実行
      await Future.delayed(const Duration(milliseconds: 1500));
      widget.onCompleted?.call();
    } catch (e, stackTrace) {
      Log.error('❌ [SIGNUP_WIDGET] サインアップ処理エラー: $e', e, stackTrace);

      setState(() {
        _isProcessing = false;
        _errorMessage = e.toString();
        _currentStep = 'エラーが発生しました';
      });

      widget.onError?.call(e.toString());
    }
  }

  void _addCompletedStep(String step) {
    setState(() {
      _completedSteps.add(step);
      _currentStep = step;
    });
  }

  /// STEP1: ユーザープロフィールの設定
  Future<void> _setupUserProfile() async {
    setState(() {
      _currentStep = 'ユーザープロフィールを設定中...';
    });

    final user = widget.user;
    String displayName = widget.displayName ?? user.displayName ?? 'ユーザー';

    // ユーザー名の優先順位決定
    try {
      final prefsName = await ref
          .read(userNameNotifierProvider.notifier)
          .restoreUserNameFromPreferences();

      if (prefsName == null || prefsName.isEmpty || prefsName == 'あなた') {
        // Firebase優先
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          displayName = user.displayName!;
          await ref
              .read(userNameNotifierProvider.notifier)
              .setUserName(displayName);
        }
      } else {
        // プリファレンス優先
        displayName = prefsName;
        await user.updateDisplayName(displayName);
        await user.reload();
      }
    } catch (e) {
      Log.warning('⚠️ [SIGNUP_WIDGET] ユーザー名決定エラー: $e');
    }

    // メールアドレスをSharedPreferencesに保存
    if (user.email != null && user.email!.isNotEmpty) {
      await UserPreferencesService.saveUserEmail(user.email!);
    }

    Log.info(
        '✅ [SIGNUP_WIDGET] ユーザープロファイル設定完了: ${AppLogger.maskName(displayName)}');
  }

  /// STEP2: ローカルデフォルトグループの検出
  Future<SharedGroup?> _detectLocalDefaultGroup() async {
    setState(() {
      _currentStep = 'ローカルデータを確認中...';
    });

    try {
      final repository = ref.read(SharedGroupRepositoryProvider);
      if (repository is HybridSharedGroupRepository) {
        final allGroups = await repository.getLocalGroups();
        final localDefaultGroup =
            allGroups.where((g) => g.groupId == 'default_group').firstOrNull;

        if (localDefaultGroup != null) {
          Log.info(
            '🔍 [SIGNUP_WIDGET] ローカルデフォルトグループ検出: ${localDefaultGroup.groupName}',
          );
          Log.info(
            '🔍 [SIGNUP_WIDGET] メンバー数: ${(localDefaultGroup.members?.length ?? 0)}',
          );
        } else {
          Log.info('💡 [SIGNUP_WIDGET] ローカルデフォルトグループなし');
        }

        return localDefaultGroup;
      }
    } catch (e) {
      Log.warning('⚠️ [SIGNUP_WIDGET] ローカルデータ検出エラー: $e');
    }

    return null;
  }

  /// STEP3: Firebase形式のデフォルトグループ作成
  Future<String> _createFirebaseDefaultGroup() async {
    setState(() {
      _currentStep = 'Firebaseデフォルトグループを作成中...';
    });

    final user = widget.user;
    final repository = ref.read(SharedGroupRepositoryProvider);
    final newGroupId = 'default_${user.uid}';

    // 既存チェック
    try {
      final existingGroup = await repository.getGroupById(newGroupId);
      Log.info(
        '✅ [SIGNUP_WIDGET] デフォルトグループは既に存在: ${existingGroup.groupName}',
      );
      return newGroupId;
    } catch (e) {
      // グループが存在しない場合は作成を続行
    }

    // オーナーメンバーを作成
    final ownerMember = SharedGroupMember.create(
      memberId: user.uid,
      name: user.displayName ?? 'ユーザー',
      contact: user.email ?? '',
      role: SharedGroupRole.owner,
    );

    // デフォルトグループを作成
    await repository.createGroup(newGroupId, 'My Lists', ownerMember);

    Log.info(
        '✅ [SIGNUP_WIDGET] Firebaseデフォルトグループ作成完了: ${AppLogger.maskGroupId(newGroupId)}');
    return newGroupId;
  }

  /// STEP4: ローカルデータの移行
  Future<void> _migrateLocalData(
    SharedGroup localDefaultGroup,
    String newGroupId,
  ) async {
    setState(() {
      _currentStep = 'ローカルデータをFirebaseに移行中...';
    });

    final user = widget.user;
    final repository = ref.read(SharedGroupRepositoryProvider);

    // メンバーの移行（オーナーのuidをFirebase UIDに変更）
    final migratedMembers = <SharedGroupMember>[];
    for (final member in localDefaultGroup.members ?? []) {
      if (member.role == SharedGroupRole.owner) {
        // オーナーのmemberIdをFirebase UIDに変更
        final updatedOwner = member.copyWith(
          memberId: user.uid,
          name: user.displayName ?? member.name,
          contact: user.email ?? '',
        );
        migratedMembers.add(updatedOwner);
      } else {
        migratedMembers.add(member);
      }
    }

    // グループの更新
    final migratedGroup = localDefaultGroup.copyWith(
      groupId: newGroupId,
      groupName: 'My Lists',
      members: migratedMembers,
      ownerUid: user.uid,
    );

    await repository.updateGroup(newGroupId, migratedGroup);

    // SharedListの移行
    await _migrateSharedLists('default_group', newGroupId);

    // デフォルトグループのownerメンバーIDをFirebase UIDに更新
    try {
      final defaultGroup = await repository.getGroupById('default_group');
      final updatedMembers = (defaultGroup.members ?? []).map((member) {
        if (member.role == SharedGroupRole.owner) {
          return member.copyWith(memberId: user.uid);
        }
        return member;
      }).toList();

      final updatedDefaultGroup = defaultGroup.copyWith(
        members: updatedMembers,
        ownerUid: user.uid,
      );

      await repository.updateGroup('default_group', updatedDefaultGroup);
      Log.info('✅ [SIGNUP_WIDGET] デフォルトグループのownerメンバーIDをFirebase UIDに更新完了');
    } catch (e) {
      Log.warning('⚠️ [SIGNUP_WIDGET] デフォルトグループ更新エラー: $e');
    }

    Log.info('✅ [SIGNUP_WIDGET] ローカルデータ移行完了');
  }

  /// SharedListの移行
  Future<void> _migrateSharedLists(String oldGroupId, String newGroupId) async {
    try {
      // SharedListの移行は簡略化（基本的なログ記録のみ）
      Log.info('💡 [SIGNUP_WIDGET] SharedList移行をスキップ（今後実装予定）');
      // TODO: 実際のSharedList移行ロジックを実装
    } catch (e) {
      Log.warning('⚠️ [SIGNUP_WIDGET] SharedList移行エラー: $e');
    }
  }

  /// STEP5: プロバイダーの更新
  Future<void> _refreshProviders() async {
    setState(() {
      _currentStep = 'アプリ状態を更新中...';
    });

    // プロバイダーを無効化して再読み込み
    ref.invalidate(allGroupsProvider);
    ref.invalidate(userNameProvider);

    // 少し待って更新を確実に
    await Future.delayed(const Duration(milliseconds: 500));

    Log.info('✅ [SIGNUP_WIDGET] プロバイダー更新完了');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // アイコンとタイトル
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_circle,
                  color: Colors.blue.shade700,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'アカウント設定中',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.user.email ?? 'ユーザー',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // プログレスインジケーター
          if (_isProcessing)
            AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                  ),
                );
              },
            )
          else if (_errorMessage != null)
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            )
          else
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 48,
            ),

          const SizedBox(height: 16),

          // 現在のステップ
          Text(
            _currentStep,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),

          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: 16),

          // 完了したステップ一覧
          if (_completedSteps.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            ..._completedSteps.map((step) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    step,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
