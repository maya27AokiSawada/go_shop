// 🚨 未使用ウィジェット - PurchaseGroupPageでの実装時に使用予定
// TODO: PurchaseGroupPageでメンバーリスト表示時に import して使用
import 'package:flutter/material.dart';
import '../utils/app_logger.dart';
import '../models/purchase_group.dart'; // Memberクラスをインポート


class MemberListTile extends StatelessWidget {
  final PurchaseGroupMember member;
  final VoidCallback? onTap;

  String makeTitle( PurchaseGroupRole role) {
   switch (role) {
     case PurchaseGroupRole.owner:
       return 'オーナー: ${member.name}';
     case PurchaseGroupRole.manager:
       return '管理者: ${member.name}';
     case PurchaseGroupRole.member:
       return 'メンバー: ${member.name}';
     case PurchaseGroupRole.friend:
       return 'フレンド: ${member.name}';
   }
 }
  const MemberListTile({
    super.key,
    required this.member,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // 左側のアイコンまたはプロフィール画像
      leading: const CircleAvatar(
        // ここにプロフィール画像を配置したり、イニシャルを表示したりできます
        child: Icon(Icons.person),
      ),
      // メンバーのフルネーム
      title: Text(makeTitle(member.role)),
      subtitle: Text("contact: ${member.contact}"),
      // タップしたときの処理
      onTap: onTap,
    );
  }
}
