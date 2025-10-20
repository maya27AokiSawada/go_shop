// lib/services/deep_link_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../utils/app_logger.dart';
import 'invitation_service.dart';

class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('deep_link');
  final Logger _logger = Logger();
  
  StreamController<String>? _linkStreamController;
  Stream<String>? _linkStream;

  DeepLinkService() {
    _linkStreamController = StreamController<String>.broadcast();
    _linkStream = _linkStreamController!.stream;
    _setupMethodCallHandler();
  }

  Stream<String> get linkStream => _linkStream!;

  void _setupMethodCallHandler() {
    try {
      _channel.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'handleDeepLink') {
          final String link = call.arguments;
          Log.info('📨 Received deep link: $link');
          _linkStreamController?.add(link);
        }
      });
    } catch (e) {
      Log.error('❌ Failed to set up deep link handler: $e');
    }
  }

  // アプリ起動時のディープリンクを処理
  static Future<void> initializeDeepLinks(BuildContext context) async {
    try {
      // アプリが既に起動している状態でリンクをクリックした場合
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'handleDeepLink') {
          final String link = call.arguments;
          await _handleIncomingLink(context, link);
        }
      });

      // アプリ起動時にリンクがある場合
      final String? initialLink = await _channel.invokeMethod('getInitialLink');
      if (initialLink != null) {
        // ignore: use_build_context_synchronously
        await _handleIncomingLink(context, initialLink);
      }
    } catch (e) {
      Log.error('Deep link initialization error: $e');
    }
  }

  static Future<void> _handleIncomingLink(BuildContext context, String link) async {
    final uri = Uri.parse(link);
    
    // 招待リンクの処理（新形式: go-shop://invite?code=ABC123）
    if (uri.scheme == 'go-shop' && uri.host == 'invite') {
      final inviteCode = uri.queryParameters['code'];
      
      if (inviteCode != null) {
        // 招待受諾画面に遷移
        Navigator.pushNamed(
          context,
          '/invitation_accept',
          arguments: {
            'inviteCode': inviteCode,
          },
        );
      }
    }
    // 旧形式のサポート（後方互換）
    else if (uri.path == '/invite') {
      final invitationId = uri.queryParameters['id'];
      final groupId = uri.queryParameters['group'];
      
      if (invitationId != null && groupId != null) {
        Navigator.pushNamed(
          context,
          '/invitation',
          arguments: {
            'invitationId': invitationId,
            'groupId': groupId,
          },
        );
      }
    }
  }

  /// 招待リンクを処理
  Future<Map<String, dynamic>?> handleInvitationLink(
    String link,
    InvitationService invitationService,
  ) async {
    try {
      Log.info('🔗 Processing invitation link: $link');
      
      final uri = Uri.parse(link);
      if (uri.scheme != 'go-shop' || uri.host != 'invite') {
        Log.warning('⚠️ Invalid invitation link format');
        return null;
      }

      final inviteCode = uri.queryParameters['code'];
      if (inviteCode == null) {
        Log.warning('⚠️ No invite code found in link');
        return null;
      }

      Log.info('🎫 Processing invite code: $inviteCode');
      
      // 招待情報を確認
      final invitationInfo = await invitationService.getInvitationByCode(inviteCode);
      if (invitationInfo == null) {
        Log.warning('⚠️ Invalid or expired invitation code');
        return null;
      }

      // 招待を受諾
      final success = await invitationService.acceptInvitation(inviteCode);
      
      if (success) {
        Log.info('✅ Invitation accepted successfully');
        return invitationInfo;
      } else {
        Log.warning('⚠️ Failed to accept invitation');
        return null;
      }
      
    } catch (e) {
      Log.error('❌ Failed to handle invitation link: $e');
      return null;
    }
  }

  void dispose() {
    _linkStreamController?.close();
  }
}

// Provider
final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = DeepLinkService();
  ref.onDispose(() => service.dispose());
  return service;
});
