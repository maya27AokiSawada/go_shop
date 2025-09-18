import 'package:flutter/material.dart';
import 'package:go_shopping/models/purchase_group.dart'; // Memberクラスをインポート


class MemberListTile extends StatelessWidget {
  final PurchaseGroupMember member;
  final VoidCallback? onTap;

  String makeTitle( PurchaseGroupRole role) {
   if ( role == PurchaseGroupRole.parent ) {
     return '親: ${member.name}';
   } else {
     return '子: ${member.name}';
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
