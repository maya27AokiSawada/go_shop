import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/app_logger.dart';
import '../providers/purchase_group_provider.dart';
import '../providers/user_name_provider.dart';
import '../providers/security_provider.dart';
import '../models/purchase_group.dart';
import '../widgets/member_selection_dialog.dart';
import '../widgets/group_selector_widget.dart';
import '../pages/group_invitation_page.dart';
// import '../widgets/auto_invite_button.dart'; // QRコード招待に変更
// import '../widgets/qr_invitation_widgets.dart'; // 一時的にコメントアウト
import '../widgets/member_role_management_widget.dart';
// import '../widgets/owner_message_widget.dart'; // 一時的にコメントアウト
import '../helpers/validation_service.dart';

class PurchaseGroupPage extends ConsumerStatefulWidget {
  const PurchaseGroupPage({super.key});

  @override
  ConsumerState<PurchaseGroupPage> createState() => _PurchaseGroupPageState();
}

class _PurchaseGroupPageState extends ConsumerState<PurchaseGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  String _getRoleDisplayName(PurchaseGroupRole role) {
    switch (role) {
      case PurchaseGroupRole.owner:
        return 'オーナー';
      case PurchaseGroupRole.manager:
        return '管理者';
      case PurchaseGroupRole.member:
        return 'メンバー';
      case PurchaseGroupRole.friend:
        return 'フレンド';
    }
  }

  /// 招待状態の表示名を取得
  String _getInvitationStatusDisplayName(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.self:
        return '';
      case InvitationStatus.pending:
        return '招待中';
      case InvitationStatus.accepted:
        return '承諾済';
      case InvitationStatus.deleted:
        return '削除済';
    }
  }

  /// 招待状態に応じたアイコンを取得
  IconData _getInvitationStatusIcon(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.self:
        return Icons.person;
      case InvitationStatus.pending:
        return Icons.schedule;
      case InvitationStatus.accepted:
        return Icons.check_circle;
      case InvitationStatus.deleted:
        return Icons.person_off;
    }
  }

  /// 招待状態に応じた色を取得
  Color _getInvitationStatusColor(InvitationStatus status) {
    switch (status) {
      case InvitationStatus.self:
        return Colors.blue;
      case InvitationStatus.pending:
        return Colors.orange;
      case InvitationStatus.accepted:
        return Colors.green;
      case InvitationStatus.deleted:
        return Colors.grey;
    }
  }

  /// 現在のユーザーが招待権限を持っているかチェック（管理者以上）
  bool _hasInvitePermission(PurchaseGroup purchaseGroup, String currentUserUid) {
    if (currentUserUid.isEmpty || purchaseGroup.members?.isEmpty == true) {
      return false;
    }
    
    // メンバーリストから現在のユーザーを検索（memberIdで検索）
    final currentMember = purchaseGroup.members?.firstWhere(
      (member) => member.memberId == currentUserUid,
      orElse: () => const PurchaseGroupMember(
        memberId: '',
        name: '',
        contact: '',
        role: PurchaseGroupRole.member,
      ),
    );
    
    // 管理者またはオーナーの場合は招待可能
    return currentMember?.role == PurchaseGroupRole.manager || 
           currentMember?.role == PurchaseGroupRole.owner;
  }

  /// 現在のユーザーがオーナーかチェック
  bool _isOwner(PurchaseGroup purchaseGroup, String currentUserUid) {
    if (currentUserUid.isEmpty || purchaseGroup.members?.isEmpty == true) {
      return false;
    }
    
    // メンバーリストから現在のユーザーを検索し、オーナーロールかチェック
    final currentMember = purchaseGroup.members?.firstWhere(
      (member) => member.memberId == currentUserUid,
      orElse: () => const PurchaseGroupMember(
        memberId: '',
        name: '', 
        contact: '', 
        role: PurchaseGroupRole.member,
      ),
    );
    
    return currentMember?.role == PurchaseGroupRole.owner;
  }

  /// 現在のユーザーをグループのオーナーとして追加
  Future<void> _addCurrentUserAsOwner(PurchaseGroup purchaseGroup, String userName, String userUid, WidgetRef ref) async {
    try {
      final newMember = PurchaseGroupMember.create(
        memberId: userUid,
        name: userName,
        contact: '', // メールアドレスは後で設定可能
        role: PurchaseGroupRole.owner,
        isSignedIn: true,
      );
      
      final updatedMembers = List<PurchaseGroupMember>.from(purchaseGroup.members ?? []);
      updatedMembers.add(newMember);
      
      final updatedGroup = purchaseGroup.copyWith(
        members: updatedMembers,
        ownerUid: userUid,
      );
      
      await ref.read(selectedGroupNotifierProvider.notifier).updateGroup(updatedGroup);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${purchaseGroup.groupName}に参加しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('グループへの参加に失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _editMember(PurchaseGroupMember member, int index) async {
    final result = await showDialog<PurchaseGroupMember>(
      context: context,
      builder: (context) => _EditMemberDialog(member: member),
    );
    
    if (result != null) {
      try {
        final currentGroup = ref.read(selectedGroupNotifierProvider).value;
        if (currentGroup != null) {
          final updatedMembers = List<PurchaseGroupMember>.from(currentGroup.members ?? []);
          updatedMembers[index] = result;
          final updatedGroup = currentGroup.copyWith(members: updatedMembers);
          await ref.read(selectedGroupNotifierProvider.notifier).updateGroup(updatedGroup);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('メンバーの更新に失敗しました: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteMember(PurchaseGroupMember member, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メンバーを削除'),
        content: Text('${member.name}をこのグループから削除しますか？\n\nこの操作は取り消せません。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final currentGroup = ref.read(selectedGroupNotifierProvider).value;
        if (currentGroup != null) {
          final member = (currentGroup.members ?? [])[index];
          await ref.read(selectedGroupNotifierProvider.notifier).deleteMember(member.memberId);
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${member.name}を削除しました')),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('メンバーの削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firebase認証情報を一度だけ取得
    final currentUser = FirebaseAuth.instance.currentUser;
    final currentUserUid = currentUser?.uid ?? '';
    final selectedGroupId = ref.watch(selectedGroupIdProvider);
    
    // セキュリティチェック
    final canViewData = ref.watch(dataVisibilityProvider);
    final authRequired = ref.watch(authRequiredProvider);
    
    if (!canViewData && authRequired) {
      return Scaffold(
        appBar: AppBar(title: const Text('グループ管理')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'シークレットモードが有効です',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'グループデータを表示するにはログインが必要です',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    final selectedGroupAsync = ref.watch(selectedGroupProvider);
    final currentUserName = ref.watch(userNameProvider);

    Log.info('🏷️ [PAGE BUILD] selectedGroupAsync状態: ${selectedGroupAsync.runtimeType}');
    Log.info('🏷️ [PAGE BUILD] selectedGroupAsync状態: ${selectedGroupAsync.runtimeType}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('グループ管理'),
        actions: [
          // 設定メニュー
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (value) {
              switch (value) {
                case 'delete_group':
                  if (selectedGroupId != 'default_group') {
                    _showDeleteGroupDialog(context, selectedGroupId);
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              if (selectedGroupId != 'default_group')
                const PopupMenuItem(
                  value: 'delete_group',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('グループを削除'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // グループ選択ウィジェット
              const GroupSelectorWidget(),
              const SizedBox(height: 16),
              // グループ内容表示 - 簡素化版
              Expanded(
                child: selectedGroupAsync.when(
                  data: (purchaseGroup) {
                    if (purchaseGroup == null) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.group_off, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              '選択されたグループが見つかりません',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          ],
                        ),
                      );
                    }
                    return SingleChildScrollView(
                      child: Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: _buildGroupContent(purchaseGroup, currentUserName.value, currentUserUid, ref),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('グループを読み込み中...'),
                      ],
                    ),
                  ),
                  error: (error, stack) {
                    Log.error('❌ [GROUP PAGE] エラー発生: $error');
                    return Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.red),
                            const SizedBox(height: 16),
                            const Text(
                              'グループの読み込みに失敗しました',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'エラー: $error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(allGroupsProvider),
                              child: const Text('再試行'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(context, selectedGroupId),
    );
  }

  Widget _buildGroupContent(PurchaseGroup purchaseGroup, String? currentUserName, String currentUserUid, WidgetRef ref) {
    // 現在のユーザーがグループのメンバーに含まれているかチェック
    final isUserMember = purchaseGroup.members?.any((member) => member.memberId == currentUserUid) ?? false;
    
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('メンバー数: ${purchaseGroup.members?.length ?? 0}'),
                    const Spacer(),
                    if (!isUserMember && currentUserUid.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () => _addCurrentUserAsOwner(purchaseGroup, currentUserName ?? 'Unknown User', currentUserUid, ref),
                        icon: const Icon(Icons.person_add, size: 16),
                        label: const Text('グループに参加', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                  ],
                ),
                if (!isUserMember && currentUserUid.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange, size: 16),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'あなたはこのグループのメンバーではありません',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                
                // オーナーからのメッセージ（一時的にシンプルなカードに変更）
                if (_isOwner(purchaseGroup, currentUserUid))
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue, size: 16),
                        SizedBox(width: 8),
                        Text('あなたはこのグループのオーナーです'),
                      ],
                    ),
                  ),
                
                const SizedBox(height: 8),
                
                // 招待ボタン（デフォルトグループ以外でのみ表示）
                if (purchaseGroup.groupId != 'default_group')
                  Column(
                    children: [
                      // 招待ボタン（管理者以上のみ表示）
                      if (_hasInvitePermission(purchaseGroup, currentUserUid))
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _navigateToInvitationPage(purchaseGroup),
                            icon: const Icon(Icons.qr_code),
                            label: const Text('招待ページを開く'),
                          ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock, color: Colors.grey[600], size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '招待権限なし',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    // スキャンボタン（全メンバー利用可能）
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('QRスキャン機能は準備中です')),
                          );
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('QRスキャン'),
                      ),
                    ),
                  ],
                ),
                
                // メール招待（コメントアウト）
                /*
                Row(
                  children: [
                    Expanded(
                      child: AutoInviteButton(group: purchaseGroup),
                    ),
                  ],
                ),
                */
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: (purchaseGroup.members?.isEmpty ?? true)
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_add, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'メンバーがいません\n新しいメンバーを追加してください',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: purchaseGroup.members!.length,
                  itemBuilder: (context, index) {
                    final member = purchaseGroup.members![index];
                    final isCurrentUser = member.name == currentUserName;
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          member.role == PurchaseGroupRole.owner ? Icons.star :
                          member.role == PurchaseGroupRole.manager ? Icons.admin_panel_settings :
                          member.role == PurchaseGroupRole.friend ? Icons.favorite :
                          Icons.person,
                          color: member.role == PurchaseGroupRole.owner ? Colors.amber :
                                 member.role == PurchaseGroupRole.manager ? Colors.blue :
                                 member.role == PurchaseGroupRole.friend ? Colors.pink :
                                 null,
                        ),
                        title: Row(
                          children: [
                            Text(member.name),
                            const SizedBox(width: 8),
                            // 招待状態表示（最新版のinvitationStatusのみ使用）
                            if (member.invitationStatus != InvitationStatus.self)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getInvitationStatusColor(member.invitationStatus).withValues(alpha: 0.1),
                                  border: Border.all(color: _getInvitationStatusColor(member.invitationStatus)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getInvitationStatusIcon(member.invitationStatus),
                                      size: 12,
                                      color: _getInvitationStatusColor(member.invitationStatus),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getInvitationStatusDisplayName(member.invitationStatus),
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _getInvitationStatusColor(member.invitationStatus),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${_getRoleDisplayName(member.role)} - ${member.contact}'),
                            if (member.invitedAt != null)
                              Text(
                                '招待日時: ${member.invitedAt!.toLocal().toString().substring(0, 16)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            if (member.acceptedAt != null)
                              Text(
                                '参加日時: ${member.acceptedAt!.toLocal().toString().substring(0, 16)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                        trailing: isCurrentUser ? const Icon(Icons.check_circle, color: Colors.green) : null,
                        onTap: () => _editMember(member, index),
                        onLongPress: member.role != PurchaseGroupRole.owner 
                          ? () => _deleteMember(member, index)
                          : null,
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 16),
        // オーナー専用: メンバーのRole管理ウィジェット
        MemberRoleManagementWidget(
          purchaseGroup: purchaseGroup,
          currentUserUid: FirebaseAuth.instance.currentUser?.uid ?? '',
        ),
      ],
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('新しいグループを作成'),
          content: TextField(
            controller: _groupNameController,
            decoration: const InputDecoration(
              labelText: 'グループ名',
              hintText: 'グループ名を入力してください',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () async {
                final groupName = _groupNameController.text.trim();
                if (groupName.isNotEmpty) {
                  // BuildContextを事前に保存
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  
                  try {
                    // 既存グループを取得して重複チェック
                    final allGroupsAsync = ref.read(allGroupsProvider);
                    final allGroups = allGroupsAsync.when(
                      data: (groups) => groups,
                      loading: () => <PurchaseGroup>[],
                      error: (_, __) => <PurchaseGroup>[],
                    );
                    
                    // バリデーション実行
                    final validation = ValidationService.validateGroupName(groupName, allGroups);
                    
                    if (validation.hasError) {
                      // エラー表示
                      if (mounted) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(validation.errorMessage!),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      return;
                    }
                    
                    // グループ作成実行
                    await ref.read(allGroupsProvider.notifier).createNewGroup(groupName);
                    
                    _groupNameController.clear();
                    if (mounted) {
                      navigator.pop();
                      messenger.showSnackBar(
                        SnackBar(content: Text('グループ「$groupName」を作成しました')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('グループの作成に失敗しました: $e')),
                      );
                    }
                  }
                }
              },
              child: const Text('作成'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteGroupDialog(BuildContext context, String? groupId) {
    if (groupId == null) return;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('グループを削除'),
          content: Text('グループ「$groupId」を削除しますか？\nこの操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                // BuildContextを事前に保存
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                
                try {
                  await ref.read(selectedGroupNotifierProvider.notifier).deleteCurrentGroup();
                  if (mounted) {
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('グループ「$groupId」を削除しました')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('グループの削除に失敗しました: $e')),
                    );
                  }
                }
              },
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  // フローティングアクションボタンの構築
  Widget _buildFloatingActionButton(BuildContext context, String? selectedGroupId) {
    return FloatingActionButton.extended(
      onPressed: () => _showActionMenu(context),
      label: const Text('追加'),
      icon: const Icon(Icons.add),
      backgroundColor: Theme.of(context).primaryColor,
    );
  }

  // 招待ページに遷移
  void _navigateToInvitationPage(PurchaseGroup group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupInvitationPage(group: group),
      ),
    );
  }

  // アクションメニューを表示（グループ追加・メンバー追加）
  void _showActionMenu(BuildContext context) {
    final selectedGroupId = ref.read(selectedGroupIdProvider);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                '追加メニュー',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: const Text('新しいグループを追加'),
              onTap: () {
                Navigator.of(context).pop();
                _showAddGroupDialog(context);
              },
            ),
            // デフォルトグループ以外でのみメンバー追加を表示
            if (selectedGroupId != 'default_group')
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('プールメンバーを追加'),
                subtitle: const Text('メンバープールから選択'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddMemberDialog(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // メンバー追加ダイアログ
  void _showAddMemberDialog(BuildContext context) async {
    final selectedMember = await showDialog<PurchaseGroupMember>(
      context: context,
      builder: (context) => const MemberSelectionDialog(),
    );

    if (selectedMember != null) {
      _addMemberToGroup(selectedMember);
    }
  }

  // グループにメンバーを追加
  void _addMemberToGroup(PurchaseGroupMember member) async {
    final selectedGroupNotifier = ref.read(selectedGroupNotifierProvider.notifier);

    try {
      await selectedGroupNotifier.addMember(member);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name}さんをメンバーに追加しました')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('メンバーの追加に失敗しました: $e')),
        );
      }
    }
  }
}

class _EditMemberDialog extends StatefulWidget {
  final PurchaseGroupMember member;

  const _EditMemberDialog({required this.member});

  @override
  State<_EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<_EditMemberDialog> {
  late TextEditingController _nameController;
  late TextEditingController _contactController;
  late PurchaseGroupRole _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.member.name);
    _contactController = TextEditingController(text: widget.member.contact);
    _selectedRole = widget.member.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('メンバー編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '名前',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: '連絡先',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<PurchaseGroupRole>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: '役割',
                border: OutlineInputBorder(),
              ),
              items: PurchaseGroupRole.values.map((role) {
                String roleName;
                switch (role) {
                  case PurchaseGroupRole.owner:
                    roleName = 'オーナー';
                    break;
                  case PurchaseGroupRole.manager:
                    roleName = '管理者';
                    break;
                  case PurchaseGroupRole.member:
                    roleName = 'メンバー';
                    break;
                  case PurchaseGroupRole.friend:
                    roleName = 'フレンド';
                    break;
                }
                return DropdownMenuItem(
                  value: role,
                  child: Text(roleName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedRole = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: _canSave() ? () {
            final updatedMember = widget.member.copyWith(
              name: _nameController.text.trim(),
              contact: _contactController.text.trim(),
              role: _selectedRole,
            );
            Navigator.of(context).pop(updatedMember);
          } : null,
          child: const Text('保存'),
        ),
      ],
    );
  }

  bool _canSave() {
    return _nameController.text.trim().isNotEmpty &&
           _contactController.text.trim().isNotEmpty;
  }
}
