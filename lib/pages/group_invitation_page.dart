import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/shared_group.dart';
import '../services/qr_invitation_service.dart';

class GroupInvitationPage extends ConsumerStatefulWidget {
  final SharedGroup group;

  const GroupInvitationPage({
    super.key,
    required this.group,
  });

  @override
  ConsumerState<GroupInvitationPage> createState() =>
      _GroupInvitationPageState();
}

class _GroupInvitationPageState extends ConsumerState<GroupInvitationPage> {
  String? _qrData;
  bool _isLoading = true;
  String? _errorMessage;
  String _invitationType = 'individual'; // 'individual' または 'friend'

  @override
  void initState() {
    super.initState();
    _generateInvitation();
  }

  Future<void> _generateInvitation() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final qrService = ref.read(qrInvitationServiceProvider);

      final invitationData = await qrService.createQRInvitationData(
        sharedGroupId: widget.group.groupId,
        groupName: widget.group.groupName,
        groupOwnerUid: widget.group.ownerUid ?? '',
        groupAllowedUids: widget.group.allowedUid,
        invitationType: _invitationType,
      );

      final qrData = jsonEncode(invitationData);

      setState(() {
        _qrData = qrData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '招待の生成に失敗しました: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('「${widget.group.groupName}」への招待'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : _buildInvitationContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'エラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _generateInvitation,
              child: const Text('再試行'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // グループ情報カード
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.group,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.group.groupName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'メンバー数: ${(widget.group.members?.length ?? 0)}人',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 招待タイプ選択セクション
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '招待タイプ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: const Text('個別グループ招待'),
                    subtitle: const Text('このグループのみにアクセス可能'),
                    value: 'individual',
                    // ignore: deprecated_member_use
                    groupValue: _invitationType,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        _invitationType = value!;
                        _generateInvitation(); // 招待データを再生成
                      });
                    },
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<String>(
                    title: const Text('フレンド招待'),
                    subtitle: const Text('あなたのすべてのグループにアクセス可能'),
                    value: 'friend',
                    // ignore: deprecated_member_use
                    groupValue: _invitationType,
                    // ignore: deprecated_member_use
                    onChanged: (value) {
                      setState(() {
                        _invitationType = value!;
                        _generateInvitation(); // 招待データを再生成
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // QRコードセクション
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'QRコードで招待',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: _qrData != null
                        ? QrImageView(
                            data: _qrData!,
                            version: QrVersions.auto,
                            size: 250.0,
                            backgroundColor: Colors.white,
                          )
                        : const SizedBox(
                            width: 200,
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'このQRコードをスキャンしてグループに参加',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 使い方説明
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '招待の仕方',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. QRコードを相手にスキャンしてもらう\n'
                    '2. 相手がアプリで承諾すると自動的にメンバーに追加されます\n'
                    '4. 承諾通知を受け取ったらグループを確認してください',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
