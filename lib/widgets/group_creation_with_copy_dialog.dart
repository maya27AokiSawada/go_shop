// lib/widgets/group_creation_with_copy_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/shared_group.dart';
import '../providers/shared_group_provider.dart';
import '../utils/app_logger.dart';
import '../services/error_log_service.dart';
import '../utils/snackbar_helper.dart';
import '../services/notification_service.dart';
import '../providers/auth_provider.dart';

/// Dialog for creating new group with option to copy members from existing group
class GroupCreationWithCopyDialog extends ConsumerStatefulWidget {
  final SharedGroup? initialSelectedGroup;

  const GroupCreationWithCopyDialog({
    super.key,
    this.initialSelectedGroup,
  });

  @override
  ConsumerState<GroupCreationWithCopyDialog> createState() =>
      _GroupCreationWithCopyDialogState();
}

class _GroupCreationWithCopyDialogState
    extends ConsumerState<GroupCreationWithCopyDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();

  SharedGroup? _selectedSourceGroup;
  final Map<String, bool> _selectedMembers = {};
  final Map<String, SharedGroupRole> _memberRoles = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 初期選択グループが指定されていれば設定
    if (widget.initialSelectedGroup != null) {
      _selectedSourceGroup = widget.initialSelectedGroup;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _updateMemberSelection();
        });
      });
    }
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('🔄 [GROUP_CREATION_WITH_COPY_DIALOG] build() 開始');

    // allGroupsProviderから既存グループを取得
    final allGroupsAsync = ref.watch(allGroupsProvider);

    return allGroupsAsync.when(
      data: (existingGroups) => _buildDialog(context, existingGroups),
      loading: () => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (error, _) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('エラー: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialog(BuildContext context, List<SharedGroup> existingGroups) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: 600,
        ),
        child: Stack(
          children: [
            // メインコンテンツ
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(12.0), // 🔥 FIX: 16→12に縮小
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          const Icon(Icons.group_add,
                              color: Colors.blue, size: 20), // 🔥 FIX: サイズ指定
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              '新しいグループを作成',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                      FontWeight.bold), // 🔥 FIX: 20→18に縮小
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero, // 🔥 FIX: パディング削減
                            constraints:
                                const BoxConstraints(), // 🔥 FIX: 最小サイズ制約なし
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close,
                                size: 20), // 🔥 FIX: サイズ指定
                          ),
                        ],
                      ),
                      const SizedBox(height: 12), // 🔥 FIX: 16→12に縮小

                      // Group name input
                      TextFormField(
                        controller: _groupNameController,
                        decoration: const InputDecoration(
                          labelText: 'グループ名 *',
                          hintText: 'グループ名を入力してください',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'グループ名を入力してください';
                          }

                          // Check for duplicate group names
                          final trimmedName = value.trim();
                          final isDuplicate = existingGroups.any((group) =>
                              group.groupName.toLowerCase() ==
                              trimmedName.toLowerCase());

                          if (isDuplicate) {
                            return 'このグループ名は既に使用されています';
                          }

                          return null;
                        },
                      ),

                      const SizedBox(height: 12), // 🔥 FIX: 16→12に縮小

                      // Source group selection
                      if (existingGroups.isNotEmpty) ...[
                        const Text(
                          'メンバーをコピーする既存グループ (任意):',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500), // 🔥 FIX: 16→14に縮小
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<SharedGroup>(
                          isExpanded: true, // 🔥 FIX: UIオーバーフロー防止
                          initialValue: () {
                            // 🔥 FIX: _selectedSourceGroupがexistingGroupsに存在するか確認
                            // 存在しない場合はnullに設定（グループ削除後など）
                            if (_selectedSourceGroup == null) return null;

                            final exists = existingGroups.any((g) =>
                                g.groupId == _selectedSourceGroup!.groupId);

                            return exists ? _selectedSourceGroup : null;
                          }(),
                          decoration: const InputDecoration(
                            hintText: 'グループを選択...',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            const DropdownMenuItem<SharedGroup>(
                              value: null,
                              child: Text('新しいグループ (メンバーなし)'),
                            ),
                            // 🔥 FIX: groupIdで重複を除去（Dropdownアサーションエラー防止）
                            ...existingGroups
                                .fold<Map<String, SharedGroup>>(
                                  {},
                                  (map, group) {
                                    map[group.groupId] = group;
                                    return map;
                                  },
                                )
                                .values
                                .map(
                                  (group) => DropdownMenuItem<SharedGroup>(
                                    value: group,
                                    child: Text(
                                      '${group.groupName} (${group.members?.length ?? 0}人)',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                          ],
                          onChanged: (group) {
                            setState(() {
                              _selectedSourceGroup = group;
                              _updateMemberSelection();
                            });
                          },
                        ),
                        const SizedBox(height: 12), // 🔥 FIX: 16→12に縮小
                      ],

                      // Member selection list
                      if (_selectedSourceGroup?.members?.isNotEmpty ==
                          true) ...[
                        const Text(
                          'コピーするメンバーとその役割を選択:',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500), // 🔥 FIX: 16→14に縮小
                        ),
                        const SizedBox(height: 8),
                        Container(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height *
                                0.3, // 🔥 FIX: 動的高さに変更
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount:
                                _selectedSourceGroup!.members?.length ?? 0,
                            itemBuilder: (context, index) {
                              final member =
                                  _selectedSourceGroup!.members![index];
                              return _buildMemberSelectionTile(member);
                            },
                          ),
                        ),
                      ] else if (_selectedSourceGroup != null) ...[
                        Container(
                          height: 60, // 🔥 FIX: 100→60に縮小
                          alignment: Alignment.center,
                          child: const Text(
                            '選択されたグループにはメンバーがいません',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12), // 🔥 FIX: フォントサイズ指定
                          ),
                        ),
                      ] else ...[
                        Container(
                          height: 60, // 🔥 FIX: 100→60に縮小
                          alignment: Alignment.center,
                          child: const Text(
                            '既存グループを選択するとメンバーをコピーできます',
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12), // 🔥 FIX: フォントサイズ指定
                            textAlign: TextAlign.center, // 🔥 FIX: センタリング
                          ),
                        ),
                      ],

                      const SizedBox(height: 12), // 🔥 FIX: 16→12に縮小

                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('キャンセル'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _createGroup,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Text('グループを作成'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // ローディングオーバーレイ
            if (_isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'グループを作成中...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelectionTile(SharedGroupMember member) {
    final memberId = member.memberId;
    final isSelected = _selectedMembers[memberId] ?? false;

    // 🔥 FIX: オーナーの役割ではなく、現在のユーザー（新グループの作成者）を除外
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;
    if (currentUser != null && member.memberId == currentUser.uid) {
      return const SizedBox.shrink(); // 自分自身は除外
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        isThreeLine: true, // 🔥 FIX: 3行レイアウトを有効化
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              _selectedMembers[memberId] = value ?? false;
              if (value == true) {
                // 🔥 FIX: 元の役割がownerの場合はmanagerに降格
                // DropdownButtonのitemsにownerが含まれないため
                _memberRoles[memberId] = member.role == SharedGroupRole.owner
                    ? SharedGroupRole.manager
                    : member.role;
              }
            });
          },
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis, // 🔥 FIX: テキストオーバーフロー対策
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 🔥 FIX: 最小サイズに制限
          children: [
            Text(
              member.contact,
              overflow: TextOverflow.ellipsis, // 🔥 FIX: テキストオーバーフロー対策
            ),
            Text(
              '現在の役割: ${_getRoleDisplayName(member.role)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis, // 🔥 FIX: テキストオーバーフロー対策
            ),
          ],
        ),
        trailing: isSelected
            ? SizedBox(
                width: 100, // 🔥 FIX: DropdownButtonの横幅を制限
                child: DropdownButton<SharedGroupRole>(
                  isExpanded: true, // 🔥 FIX: 幅いっぱいに表示
                  value: _memberRoles[memberId],
                  onChanged: (role) {
                    if (role != null) {
                      setState(() {
                        _memberRoles[memberId] = role;
                      });
                    }
                  },
                  items: SharedGroupRole.values
                      .where((role) =>
                          role !=
                          SharedGroupRole.owner) // Don't allow owner role
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              _getRoleDisplayName(role),
                              overflow: TextOverflow
                                  .ellipsis, // 🔥 FIX: テキストオーバーフロー対策
                            ),
                          ))
                      .toList(),
                ),
              )
            : null,
      ),
    );
  }

  String _getRoleDisplayName(SharedGroupRole role) {
    switch (role) {
      case SharedGroupRole.owner:
        return 'オーナー';
      case SharedGroupRole.manager:
        return '管理者';
      case SharedGroupRole.member:
        return 'メンバー';
      case SharedGroupRole.partner:
        return 'パートナー';
    }
  }

  void _updateMemberSelection() {
    _selectedMembers.clear();
    _memberRoles.clear();

    // 🔥 FIX: _selectedSourceGroupがnullの場合は何もしない
    if (_selectedSourceGroup == null) {
      return;
    }

    // 🔥 FIX: 現在のユーザーを取得して除外対象にする
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.value;

    final members = _selectedSourceGroup!.members;
    if (members != null) {
      for (final member in members) {
        // 🔥 FIX: オーナー役割ではなく、現在のユーザー（作成者）を除外
        if (currentUser == null || member.memberId != currentUser.uid) {
          // 現在のユーザー以外は自動選択（デフォルトでチェック）
          _selectedMembers[member.memberId] = true;
          // 🔥 元の役割がownerの場合はmanagerに降格
          _memberRoles[member.memberId] = member.role == SharedGroupRole.owner
              ? SharedGroupRole.manager
              : member.role;
        }
      }
    }
  }

  Future<void> _createGroup() async {
    AppLogger.info('🔵 [CREATE GROUP DIALOG] _createGroup() メソッド開始');
    final groupName = _groupNameController.text.trim();
    AppLogger.info('🔵 [CREATE GROUP DIALOG] 入力されたグループ名: $groupName');

    // バリデーションチェック
    AppLogger.info('🔵 [CREATE GROUP DIALOG] バリデーション開始');
    if (!_formKey.currentState!.validate()) {
      AppLogger.info('🔴 [CREATE GROUP DIALOG] バリデーション失敗');
      // バリデーション失敗時に重複チェック
      final allGroupsAsync = ref.watch(allGroupsProvider);
      final allGroups = await allGroupsAsync.when(
        data: (groups) async => groups,
        loading: () async => <SharedGroup>[],
        error: (_, __) async => <SharedGroup>[],
      );

      final isDuplicate = allGroups.any(
          (group) => group.groupName.toLowerCase() == groupName.toLowerCase());

      if (isDuplicate && groupName.isNotEmpty) {
        // エラーログに記録
        AppLogger.info('⚠️ [CREATE GROUP] バリデーション失敗 - 重複グループ名');
        await ErrorLogService.logValidationError(
          'グループ作成',
          '「$groupName」という名前のグループは既に存在します',
        );
        AppLogger.info('✅ [CREATE GROUP] エラーログ記録完了（バリデーション失敗）');
      }
      return;
    }

    AppLogger.info('✅ [CREATE GROUP DIALOG] バリデーション成功');
    AppLogger.info('🔄 [CREATE GROUP DIALOG] グループ作成開始');
    setState(() {
      _isLoading = true;
      AppLogger.info('✅ [CREATE GROUP DIALOG] _isLoading = true に設定');
    });

    final hasMembersToAdd = _selectedMembers.values.any((selected) => selected);

    try {
      // 🔥 同じ名前のグループが既に存在しないかチェック
      // 🔥 FIX: ref.watch() → ref.read() に修正（async メソッド内では ref.read() を使用）
      final allGroups = await ref.read(allGroupsProvider.future);

      AppLogger.info('🔍 [CREATE GROUP] グループ数: ${allGroups.length}');
      for (final g in allGroups) {
        AppLogger.info('🔍 [CREATE GROUP] 既存グループ: ${g.groupName}');
      }

      final duplicateName =
          allGroups.any((group) => group.groupName == groupName);
      AppLogger.info(
          '🔍 [CREATE GROUP] 重複チェック結果: $duplicateName (入力: $groupName)');

      if (duplicateName) {
        AppLogger.info('⚠️ [CREATE GROUP] 重複検出 - エラーログ記録開始');

        // エラーログに記録
        try {
          await ErrorLogService.logValidationError(
            'グループ作成',
            '「$groupName」という名前のグループは既に存在します',
          );
          AppLogger.info('✅ [CREATE GROUP] エラーログ記録完了');
        } catch (e) {
          AppLogger.error('❌ [CREATE GROUP] エラーログ記録失敗: $e');
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          SnackBarHelper.showWarning(
            context,
            '「$groupName」という名前のグループは既に存在します',
          );
        }
        return;
      }

      AppLogger.info('🔄 [CREATE GROUP DIALOG] createNewGroup() 呼び出し');
      // Create new group
      await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
      AppLogger.info('✅ [CREATE GROUP DIALOG] createNewGroup() 完了');

      // 🔥 FIX (2026-02-26): iOS対応 - invalidate()を再追加
      // createNewGroup()内で状態を直接更新しているが、iOSではinvalidate()が必要
      // Androidでは直接更新のみで動作するが、iOSでは明示的なinvalidateが必要
      ref.invalidate(allGroupsProvider);
      AppLogger.info(
          '🔄 [CREATE GROUP DIALOG] allGroupsProvider invalidate完了（iOS対応）');

      // 🔥 NEW (2026-02-28): Firestore同期完了を実際に待機
      // ユーザー要望: 「グループがFirestoreにセーブできるまでダークオーバーレイとスピナーを表示」
      // 固定時間待機ではなく、プロバイダー更新の完了を実際に確認
      AppLogger.info('⏳ [CREATE GROUP DIALOG] Firestore同期完了を待機中...');
      try {
        await ref.read(allGroupsProvider.future);
        AppLogger.info('✅ [CREATE GROUP DIALOG] Firestore同期完了（プロバイダー更新完了）');
      } catch (e) {
        AppLogger.error('❌ [CREATE GROUP DIALOG] Firestore同期エラー: $e');
        // エラーでも続行（ローカルには作成済み）
      }

      // UI安定化のため少し待機（iOSは少し長めの待機が必要）
      await Future.delayed(const Duration(milliseconds: 300));
      AppLogger.info('✅ [CREATE GROUP DIALOG] UI安定化待機完了');

      // 🔥🔥🔥 CRITICAL DEBUG - このログが表示されれば、この行までは到達している
      AppLogger.info('🔥🔥🔥 [CRITICAL DEBUG] newGroupId取得ブロック開始');
      AppLogger.info(
          '🔥🔥🔥 [CRITICAL DEBUG] hasMembersToAdd: $hasMembersToAdd');

      // 🔥 FIX: メンバーコピーがある場合、プロバイダー更新後にメンバーを追加
      // この時点で新しいグループがallGroupsProviderに含まれている
      String? newGroupId;
      if (hasMembersToAdd) {
        // 🔥🔥🔥 CRITICAL DEBUG - このログが表示されればif分岐に入った
        AppLogger.info('🔥🔥🔥 [CRITICAL DEBUG] if分岐に入りました - メンバーコピーパス');
        AppLogger.info('🔄 [CREATE GROUP DIALOG] メンバー追加開始');
        newGroupId = await _addMembersToNewGroup(groupName);
        AppLogger.info(
            '✅ [CREATE GROUP DIALOG] メンバー追加完了（グループID: ${AppLogger.maskGroupId(newGroupId, currentUserId: ref.read(authStateProvider).value?.uid)}）');
      } else {
        // 🔥🔥🔥 CRITICAL DEBUG - このログが表示されればelse分岐に入った
        AppLogger.info('🔥🔥🔥 [CRITICAL DEBUG] else分岐に入りました - 新規グループ作成パス');
        // 🔥 NEW: 新規グループ作成時もgroupIdを取得
        AppLogger.info('🔄 [CREATE GROUP DIALOG] 新規グループのgroupId取得開始');
        final allGroups = await ref.read(allGroupsProvider.future);
        // 最新のグループを取得（作成したばかりのグループ）
        final latestGroup = allGroups.firstWhere(
          (group) => group.groupName == groupName,
          orElse: () => throw Exception('作成したグループが見つかりません'),
        );
        newGroupId = latestGroup.groupId;
        AppLogger.info(
            '✅ [CREATE GROUP DIALOG] 新規グループのgroupId取得完了: ${AppLogger.maskGroupId(newGroupId, currentUserId: ref.read(authStateProvider).value?.uid)}');
      }

      // 🔥 FIX: invalidate()を削除（メンバー追加は_addMembersToNewGroup内で完了）
      // メンバー追加後も状態は自動的に更新される
      if (hasMembersToAdd) {
        // UI安定化のため少し待機
        await Future.delayed(const Duration(milliseconds: 300));
        AppLogger.info('✅ [CREATE GROUP DIALOG] メンバー追加後のUI安定化完了');
      }

      // 🔥 FIX: メンバーコピーは新グループ作成時に追加済み（_addSelectedMembersは削除）
      // メンバーに通知を送信（新規グループ作成時は作成者自身にも送信）
      if (newGroupId != null) {
        AppLogger.info('🔄 [CREATE GROUP DIALOG] メンバー通知送信開始');

        // 🔥 CRITICAL: Widget dispose前にrefを使用してサービス・ユーザー情報を取得
        final notificationService = ref.read(notificationServiceProvider);
        final authState = ref.read(authStateProvider);
        final currentUser = authState.value;
        final senderName = currentUser?.displayName ?? 'ユーザー';

        if (currentUser != null) {
          // 🔥 FIX: メンバーがいる場合は既存ロジック、いない場合は作成者自身に通知
          if (hasMembersToAdd) {
            // コピー元グループのメンバーに通知
            await _sendMemberNotifications(
              notificationService,
              currentUser.uid,
              senderName,
              newGroupId,
              groupName,
            );
            // 🔥 P1 #2 FIX: コピー付き作成でも作成者自身に通知を送信（他デバイス同期用）
            // _sendMemberNotifications()は_selectedMembersを参照するが、
            // _updateMemberSelection()で作成者は_selectedMembersから除外されるため
            // 自分への通知が送信されない問題を修正
            try {
              await notificationService.sendNotification(
                targetUserId: currentUser.uid,
                type: NotificationType.groupMemberAdded,
                groupId: newGroupId,
                message: '新しいグループ「$groupName」を作成しました',
                metadata: {
                  'groupId': newGroupId,
                  'groupName': groupName,
                  'createdBy': currentUser.uid,
                  'createdByName': senderName,
                },
              ).timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  AppLogger.warning('⏱️ [CREATE GROUP DIALOG] 作成者通知タイムアウト');
                  throw TimeoutException('通知送信がタイムアウトしました');
                },
              );
              AppLogger.info('✅ [CREATE GROUP DIALOG] コピー付き作成 - 作成者への通知送信完了');
            } catch (e) {
              AppLogger.error('❌ [CREATE GROUP DIALOG] 作成者への通知送信エラー: $e');
            }
          } else {
            // 🔥 NEW: 新規グループ作成時は作成者の他デバイスに通知
            AppLogger.info('🔄 [CREATE GROUP DIALOG] 新規グループ作成 - 作成者に通知送信');
            try {
              await notificationService.sendNotification(
                targetUserId: currentUser.uid,
                type: NotificationType.groupMemberAdded,
                groupId: newGroupId,
                message: '新しいグループ「$groupName」を作成しました',
                metadata: {
                  'groupId': newGroupId,
                  'groupName': groupName,
                  'createdBy': currentUser.uid,
                  'createdByName': senderName,
                },
              ).timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  AppLogger.warning('⏱️ [CREATE GROUP DIALOG] 通知送信タイムアウト');
                  throw TimeoutException('通知送信がタイムアウトしました');
                },
              );
              AppLogger.info('✅ [CREATE GROUP DIALOG] 作成者への通知送信完了');
            } catch (e) {
              AppLogger.error('❌ [CREATE GROUP DIALOG] 作成者への通知送信エラー: $e');
            }
          }
          AppLogger.info('✅ [CREATE GROUP DIALOG] メンバー通知送信完了');
        } else {
          AppLogger.warning(
              '⚠️ [CREATE GROUP DIALOG] currentUserがnull - 通知送信スキップ');
        }
      }

      // ✅ グループ作成処理完了
      AppLogger.info(
          '✅ [CREATE GROUP DIALOG] グループ作成処理完了: ${AppLogger.maskName(groupName)}');
      AppLogger.info('🔍 [CREATE GROUP DIALOG] mounted状態: $mounted');

      // ローディング解除 - ユーザーに完了を視覚的に示す
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        AppLogger.info('✅ [CREATE GROUP DIALOG] ローディング解除完了');
      }

      // 🆕 Windowsでのプロバイダー反映待機
      // 楽観的更新から実際のUI反映まで時間がかかることがあるため
      AppLogger.info('⏳ [CREATE GROUP DIALOG] UI反映完了を待機中...');
      await Future.delayed(const Duration(milliseconds: 500));
      AppLogger.info('✅ [CREATE GROUP DIALOG] UI反映待機完了');

      if (mounted) {
        AppLogger.info('🔄 [CREATE GROUP DIALOG] Navigator.pop(true)を呼び出します');
        try {
          Navigator.of(context).pop(true);
          AppLogger.info('✅ [CREATE GROUP DIALOG] Navigator.pop()完了');
        } catch (e, stackTrace) {
          AppLogger.error('❌ [CREATE GROUP DIALOG] Navigator.pop()でエラー: $e');
          AppLogger.error('❌ [CREATE GROUP DIALOG] スタックトレース: $stackTrace');
        }
      } else {
        AppLogger.warning('⚠️ [CREATE GROUP DIALOG] mounted=false, popをスキップ');
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ [CREATE GROUP DIALOG] グループ作成エラー: $e');
      AppLogger.error('❌ [CREATE GROUP DIALOG] スタックトレース: $stackTrace');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // エラー時はfalseを返す（Snackbarは呼び出し元で表示）
        Navigator.of(context).pop(false);
      }
    }
  }

  /// 🔥 NEW: 新規作成したグループにメンバーを追加
  /// 戻り値: 新しく作成したグループのID
  Future<String?> _addMembersToNewGroup(String groupName) async {
    try {
      if (_selectedSourceGroup?.members == null) {
        AppLogger.warning('⚠️ [ADD MEMBERS TO NEW GROUP] メンバーがnull');
        return null;
      }

      // 🔥 FIX: ref.watch() → ref.read() に修正（async メソッド内では ref.read() を使用）
      final currentUser = ref.read(authStateProvider).value;
      if (currentUser == null) {
        AppLogger.warning('⚠️ [ADD MEMBERS TO NEW GROUP] currentUserがnull');
        return null;
      }

      // 新規作成したグループを取得
      // 🔥 FIX: ref.watch() + .when() パターン → ref.read(.future) に修正
      // ref.watch()はasyncメソッド内ではloading状態を返す可能性があり、
      // 空リストが返されてfirstWhereが失敗する根本原因だった
      final allGroups = await ref.read(allGroupsProvider.future);

      final newGroup = allGroups.firstWhere(
        (g) => g.groupName == groupName,
        orElse: () => throw Exception('新規作成したグループが見つかりません: $groupName'),
      );

      AppLogger.info(
          '✅ [ADD MEMBERS TO NEW GROUP] 新グループ取得: ${AppLogger.maskGroup(newGroup.groupName, newGroup.groupId)}');

      // 選択されたメンバーリストを作成
      final membersToAdd = <SharedGroupMember>[];
      final members = _selectedSourceGroup!.members;

      if (members != null) {
        for (final member in members) {
          final memberId = member.memberId;
          final isSelected = _selectedMembers[memberId] ?? false;

          // 現在のユーザー（作成者）は除外
          if (isSelected && member.memberId != currentUser.uid) {
            final newRole = _memberRoles[memberId] ?? member.role;

            final newMember = SharedGroupMember.create(
              memberId: member.memberId,
              name: member.name,
              contact: member.contact,
              role: newRole,
            );

            membersToAdd.add(newMember);
            AppLogger.info(
                '📝 [ADD MEMBERS TO NEW GROUP] 追加予定: ${AppLogger.maskName(member.name)} (役割: ${_getRoleDisplayName(newRole)})');
          }
        }
      }

      if (membersToAdd.isEmpty) {
        AppLogger.info('⚠️ [ADD MEMBERS TO NEW GROUP] 追加するメンバーがいません');
        return newGroup.groupId;
      }

      // 既存のメンバーリスト（オーナーのみ）に新メンバーを追加
      final existingMembers = newGroup.members ?? [];
      final updatedMembers = [...existingMembers, ...membersToAdd];

      // allowedUidリストも更新
      final existingAllowedUids = newGroup.allowedUid;
      final newAllowedUids = membersToAdd.map((m) => m.memberId).toList();
      final updatedAllowedUids = [...existingAllowedUids, ...newAllowedUids];

      // グループを更新
      final updatedGroup = newGroup.copyWith(
        members: updatedMembers,
        allowedUid: updatedAllowedUids,
      );

      AppLogger.info(
          '🔄 [ADD MEMBERS TO NEW GROUP] グループ更新開始: ${membersToAdd.length}人追加');

      // Firestoreに保存
      final repository = ref.read(SharedGroupRepositoryProvider);
      await repository.updateGroup(updatedGroup.groupId, updatedGroup);

      AppLogger.info('✅ [ADD MEMBERS TO NEW GROUP] グループ更新完了');

      // 🔥 FIX: プロバイダー無効化は呼び出し元（_createGroup）で実行
      // ここで実行するとダイアログが閉じられた後にrefを使用するリスクがある
      return newGroup.groupId;
    } catch (e, stackTrace) {
      AppLogger.error('❌ [ADD MEMBERS TO NEW GROUP] メンバー追加処理でエラー発生: $e');
      AppLogger.error('❌ [ADD MEMBERS TO NEW GROUP] スタックトレース: $stackTrace');
      rethrow;
    }
  }

  /// 🔥 NEW: メンバーに通知のみ送信（グループには作成時に追加済み）
  /// notificationService, currentUid, senderNameは呼び出し元で取得済み（Widget dispose対策）
  Future<void> _sendMemberNotifications(
    NotificationService notificationService,
    String currentUid,
    String senderName,
    String groupId,
    String groupName,
  ) async {
    try {
      if (_selectedSourceGroup?.members == null) {
        return;
      }
      final members = _selectedSourceGroup!.members;

      if (members != null) {
        for (final member in members) {
          final memberId = member.memberId;
          final isSelected = _selectedMembers[memberId] ?? false;

          // 🔥 FIX: 自分自身にも通知を送信（他デバイス同期用）
          if (isSelected) {
            try {
              // 🔥 FIX: タイムアウトを設定（5秒）
              await notificationService.sendNotification(
                targetUserId: member.memberId,
                type: NotificationType.groupMemberAdded,
                groupId: groupId,
                message: '$senderName さんが「$groupName」にあなたを追加しました',
                metadata: {
                  'groupId': groupId,
                  'groupName': groupName,
                  'addedBy': currentUid,
                  'addedByName': senderName,
                },
              ).timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  AppLogger.warning(
                      '⏱️ [SEND NOTIFICATIONS] 通知送信タイムアウト: ${AppLogger.maskName(member.name)}');
                  throw TimeoutException('通知送信がタイムアウトしました');
                },
              );
              AppLogger.info(
                  '✅ [SEND NOTIFICATIONS] 通知送信完了: ${AppLogger.maskName(member.name)}');
            } catch (e) {
              AppLogger.error(
                  '❌ [SEND NOTIFICATIONS] 通知送信エラー: ${AppLogger.maskName(member.name)} - $e');
              // 個別のメンバー通知失敗は続行（他のメンバーには送信）
            }
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('❌ [SEND NOTIFICATIONS] 通知送信処理でエラー発生: $e');
      AppLogger.error('❌ [SEND NOTIFICATIONS] スタックトレース: $stackTrace');
      // エラーでも処理を続行（通知は必須ではない）
    }
  }
}

/// Show group creation with copy dialog
Future<bool?> showGroupCreationWithCopyDialog({
  required BuildContext context,
}) async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => const GroupCreationWithCopyDialog(),
  );
}
