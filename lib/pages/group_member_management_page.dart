import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/shared_group.dart';
import '../providers/shared_group_provider.dart';
import '../utils/app_logger.dart';
// 🔥 REMOVED: import '../utils/group_helpers.dart'; デフォルトグループ機能削除
import '../widgets/member_selection_dialog.dart';
import '../pages/group_invitation_page.dart';
import '../widgets/member_tile_with_whiteboard.dart';
import '../widgets/group_creation_with_copy_dialog.dart';

/// グループのメンバー管理画面
/// 招待→ユーザー情報セットの流れに対応
class GroupMemberManagementPage extends ConsumerStatefulWidget {
  final SharedGroup group;

  const GroupMemberManagementPage({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupMemberManagementPage> createState() =>
      _GroupMemberManagementPageState();
}

class _GroupMemberManagementPageState
    extends ConsumerState<GroupMemberManagementPage> {
  // 🔥 REMOVED: デフォルトグループ機能廃止
  late final TextEditingController _groupNameController;
  late String _displayGroupName;

  @override
  void initState() {
    super.initState();
    _displayGroupName = widget.group.groupName;
    _groupNameController = TextEditingController(text: widget.group.groupName);
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // allGroupsProviderから対象グループを取得（リアルタイム更新対応）
    final allGroupsAsync = ref.watch(allGroupsProvider);

    allGroupsAsync.whenData((groups) {
      final latestGroup = groups.firstWhere(
        (g) => g.groupId == widget.group.groupId,
        orElse: () => widget.group,
      );

      if (_displayGroupName != latestGroup.groupName) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _displayGroupName = latestGroup.groupName;
            _groupNameController.text = latestGroup.groupName;
          });
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_displayGroupName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.content_copy),
            tooltip: 'このグループをコピーして新規作成',
            onPressed: () async {
              // 🔥 同期完了を待機（同期中作成による赤画面エラーを防止）
              try {
                await ref.read(allGroupsProvider.future);
                AppLogger.info(
                    '✅ [GROUP_COPY] allGroupsProvider同期完了 - ダイアログ表示');
              } catch (e) {
                AppLogger.error('❌ [GROUP_COPY] allGroupsProvider読み込みエラー: $e');
                // エラーでもダイアログ表示は継続（Hiveフォールバック）
              }

              if (!mounted) return;

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupCreationWithCopyDialog(
                    initialSelectedGroup: widget.group,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'メンバーを招待',
            onPressed: () {
              // 権限チェック
              if (!_canInviteMembers()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('メンバーを招待できるのはオーナー、管理者、パートナーのみです'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      GroupInvitationPage(group: widget.group),
                ),
              );
            },
          ),
        ],
      ),
      body: allGroupsAsync.when(
        data: (groups) {
          // 対象グループを検索
          final targetGroup = groups.firstWhere(
            (g) => g.groupId == widget.group.groupId,
            orElse: () => widget.group, // 見つからない場合は初期値を使用
          );
          return _buildMemberList(targetGroup);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text('エラーが発生しました'),
              const SizedBox(height: 8),
              Text(error.toString()),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allGroupsProvider),
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMemberList(SharedGroup group) {
    final members = group.members ?? [];

    // グループ情報ヘッダーウィジェット
    final headerWidget = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50, // 🔥 REMOVED: デフォルトグループ判定削除
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'グループ情報',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700, // 🔥 REMOVED: デフォルトグループ判定削除
            ),
          ),
          const SizedBox(height: 8),
          // グループ名編集TextField
          Row(
            children: [
              const Text('グループ名: '),
              Expanded(
                child: TextField(
                  controller: _groupNameController,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) => _updateGroupName(group, value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('メンバー数: ${members.length}人'),
          if (group.ownerName?.isNotEmpty == true)
            Text('オーナー: ${group.ownerName}'),
        ],
      ),
    );

    // メンバーリストウィジェット（スクロールビュー対応）
    Widget buildMemberListForScroll() {
      if (members.isEmpty) {
        return _buildEmptyMemberList();
      }
      return ListView.builder(
        shrinkWrap: true, // 🔥 スクロールビュー内で使用するため必須
        physics: const NeverScrollableScrollPhysics(), // 🔥 親のスクロールに委譲
        itemCount: members.length,
        itemBuilder: (context, index) {
          final member = members[index];
          return MemberTileWithWhiteboard(
            member: member,
            groupId: group.groupId,
          );
        },
      );
    }

    // メンバーリストウィジェット（Expanded用、元の実装）
    final memberListWidget = members.isEmpty
        ? _buildEmptyMemberList()
        : ListView.builder(
            itemCount: members.length,
            itemBuilder: (context, index) {
              final member = members[index];
              return MemberTileWithWhiteboard(
                member: member,
                groupId: group.groupId,
              );
            },
          );

    // 画面サイズとアスペクト比を取得
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final aspectRatio = screenWidth / screenHeight;

    // 2カラムレイアウト有効条件
    // - 横幅1000px以上（快適な左右分割）
    // - 縦幅600px以上（メンバーリストを快適表示）
    // - アスペクト比1.2以上（横長画面: Pixel 9ポートレート除外）
    final isWideScreen =
        screenWidth >= 1000 && screenHeight >= 600 && aspectRatio > 1.2;

    // スマホのランドスケープ警告: 横長だが高さが狭い
    // - small_Phone (800x480)、通常スマホの横向き含む
    final isNarrowLandscape = aspectRatio > 1.0 && screenHeight < 600;

    // ランドスケープ警告バナー（スマホの横向き時）
    Widget? landscapeWarningBanner;
    if (isNarrowLandscape) {
      landscapeWarningBanner = Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.shade100,
          border: Border(
            bottom: BorderSide(color: Colors.orange.shade300),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.screen_rotation,
                color: Colors.orange.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '縦向きでの使用を推奨します',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isWideScreen) {
      // 横長画面: 左右分割レイアウト（タブレット等）
      return Column(
        children: [
          if (landscapeWarningBanner != null) landscapeWarningBanner,
          Expanded(
            child: Row(
              children: [
                // 左側: グループ情報＋ホワイトボードプレビュー
                Expanded(
                  flex: 1,
                  child: SingleChildScrollView(
                    child: headerWidget,
                  ),
                ),
                // 仕切り線
                VerticalDivider(
                  width: 1,
                  color: Colors.grey.shade200,
                ),
                // 右側: メンバーリスト
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Text(
                          'メンバーリスト',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      Expanded(child: memberListWidget),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      // 縦長画面 or スマホのランドスケープ: スクロール対応レイアウト
      return Column(
        children: [
          if (landscapeWarningBanner != null) landscapeWarningBanner,
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  headerWidget,
                  // メンバーリストヘッダー
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Text(
                      'メンバーリスト',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  // メンバーリスト本体（shrinkWrap対応版）
                  buildMemberListForScroll(),
                ],
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildEmptyMemberList() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.group_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'メンバーがいません',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          const Text(
            '右上の + ボタンから\nメンバーを招待してください',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showInviteOptions(context),
            icon: const Icon(Icons.person_add),
            label: const Text('メンバーを招待'),
          ),
        ],
      ),
    );
  }

  /// 現在のユーザーが招待権限を持っているかチェック
  bool _canInviteMembers() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final currentMember = widget.group.members?.firstWhere(
      (member) => member.memberId == currentUser.uid,
      orElse: () => const SharedGroupMember(
        memberId: '',
        name: '',
        contact: '',
        role: SharedGroupRole.member,
      ),
    );

    // owner、manager、partnerのみ招待可能
    return currentMember != null &&
        (currentMember.role == SharedGroupRole.owner ||
            currentMember.role == SharedGroupRole.manager ||
            currentMember.role == SharedGroupRole.partner);
  }

  void _showInviteOptions(BuildContext context) {
    // 権限チェック
    if (!_canInviteMembers()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('メンバーを招待できるのはオーナー、管理者、パートナーのみです'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'メンバー招待方法を選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.qr_code, color: Colors.blue),
              title: const Text('QRコードで招待'),
              subtitle: const Text('QRコードを生成して相手にスキャンしてもらう'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GroupInvitationPage(group: widget.group),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.green),
              title: const Text('メールで招待'),
              subtitle: const Text('メールアドレスを指定して招待を送信'),
              onTap: () {
                Navigator.pop(context);
                _showEmailInviteDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.orange),
              title: const Text('手動でメンバー追加'),
              subtitle: const Text('メンバー情報を直接入力'),
              onTap: () {
                Navigator.pop(context);
                _showAddMemberDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEmailInviteDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メールで招待'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('招待するメールアドレスを入力してください'),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                _sendEmailInvitation(emailController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('招待を送信'),
          ),
        ],
      ),
    );
  }

  void _showAddMemberDialog() {
    showDialog(
      context: context,
      builder: (context) => const MemberSelectionDialog(),
    ).then((member) {
      if (member != null && member is SharedGroupMember) {
        _addMember(member);
      }
    });
  }

  void _addMember(SharedGroupMember member) async {
    try {
      await ref.read(SharedGroupRepositoryProvider).addMember(
            widget.group.groupId,
            member,
          );

      AppLogger.info('✅ [MEMBER_MGMT] メンバー追加完了: ${member.name}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${member.name} を追加しました')),
      );

      // 🔥 修正: SnackBar表示後にinvalidate
      ref.invalidate(selectedGroupProvider);
    } catch (e) {
      AppLogger.error('❌ [MEMBER_MGMT] メンバー追加エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('追加に失敗しました: $e')),
      );
    }
  }

  void _sendEmailInvitation(String email) {
    // メール招待機能は実装しない（QR招待を使用）
    AppLogger.info('📧 [MEMBER_MGMT] メール招待は未実装: $email');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('メール招待は利用できません。QR招待をご利用ください。'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// グループ名を更新
  void _updateGroupName(SharedGroup group, String newName) async {
    if (newName.isEmpty || newName.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('グループ名を入力してください'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (newName == group.groupName) {
      // 変更なし
      return;
    }

    try {
      final trimmedName = newName.trim();

      // グループ名を更新
      final updatedGroup = group.copyWith(groupName: trimmedName);
      await ref.read(SharedGroupRepositoryProvider).updateGroup(
            group.groupId,
            updatedGroup,
          );

      if (!mounted) return;

      setState(() {
        _displayGroupName = trimmedName;
        _groupNameController.text = trimmedName;
      });

      AppLogger.info('✅ [GROUP_MGMT] グループ名更新完了: $trimmedName');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('グループ名を「$trimmedName」に変更しました')),
      );

      // 🔥 修正: SnackBar表示後にinvalidate（プロバイダーを更新）
      ref.invalidate(allGroupsProvider);
    } catch (e) {
      AppLogger.error('❌ [GROUP_MGMT] グループ名更新エラー: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }
}
