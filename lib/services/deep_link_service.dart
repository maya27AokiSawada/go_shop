// lib/services/deep_link_service.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';

class DeepLinkService {
  static const MethodChannel _channel = MethodChannel('deep_link');
  
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
      logger.e('Deep link initialization error: $e');
    }
  }

  static Future<void> _handleIncomingLink(BuildContext context, String link) async {
    final uri = Uri.parse(link);
    
    // 招待リンクの処理
    if (uri.path == '/invite') {
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
}

// main.dartでの使用例
/*
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  F.appFlavor = Flavor.dev;
  await _initializeHive();
  
  runApp(
    ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Go Shop',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/invitation': (context) => _buildInvitationPage(context),
        '/login': (context) => const LoginPage(),
      },
      builder: (context, child) {
        // アプリ起動時にディープリンクを初期化
        DeepLinkService.initializeDeepLinks(context);
        return child!;
      },
    );
  }

  Widget _buildInvitationPage(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, String>;
    return InvitationPage(
      invitationId: args['invitationId']!,
      groupId: args['groupId']!,
    );
  }
}
*/
