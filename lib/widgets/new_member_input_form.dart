// 🚨 未使用ウィジェット - PurchaseGroupPageでの実装時に使用予定
// TODO: PurchaseGroupPageでメンバー追加フォーム実装時に import して使用
// lib/widgets/new_member_input_form.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/purchase_group.dart';
import '../providers/purchase_group_provider.dart';

class PurchaseGroupMemberForm extends ConsumerStatefulWidget {
  const PurchaseGroupMemberForm({super.key});

  @override
  ConsumerState<PurchaseGroupMemberForm> createState() =>
      _PurchaseGroupMemberFormState();
}

class _PurchaseGroupMemberFormState
    extends ConsumerState<PurchaseGroupMemberForm> {
  final formKey = GlobalKey<FormState>();
  String name = '';
  PurchaseGroupRole _selectedRole = PurchaseGroupRole.member;
  String contact = '';

  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'メールアドレスを入力してください';
    }
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    if (!emailRegex.hasMatch(value)) {
      return '無効なメールアドレスです';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(selectedGroupNotifierProvider);

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextFormField(
            decoration: const InputDecoration(labelText: '名前'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return '名前を入力してください';
              }
              return null;
            },
            onSaved: (value) {
              name = value!;
            },
          ),
          const SizedBox(height: 16.0),
          TextFormField(
            decoration: const InputDecoration(labelText: '連絡先'),
            validator: validateEmail,
            onSaved: (value) {
              contact = value!;
            },
          ),
          const SizedBox(height: 16.0),
          const Text('役割を選択してください:', style: TextStyle(fontSize: 16)),
          // ignore: deprecated_member_use
          RadioListTile<PurchaseGroupRole>(
            title: const Text('メンバー'),
            value: PurchaseGroupRole.member,
            // ignore: deprecated_member_use
            groupValue: _selectedRole,
            // ignore: deprecated_member_use
            onChanged: (PurchaseGroupRole? value) {
              setState(() {
                _selectedRole = value ?? PurchaseGroupRole.member;
              });
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();
                final newMember = PurchaseGroupMember(
                  memberId: const Uuid().v4(), // ユニークなIDを生成
                  name: name,
                  contact: contact,
                  role: _selectedRole,
                  invitedAt: DateTime.now(),
                  isInvited: true,
                  isInvitationAccepted: false,
                );
                ref
                    .read(selectedGroupNotifierProvider.notifier)
                    .addMember(newMember);
                Navigator.pop(context, newMember);
              }
            },
            child: const Text('追加'),
          ),
        ],
      ),
    );
  }
}
