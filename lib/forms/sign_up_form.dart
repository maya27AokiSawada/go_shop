import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/app_ui_mode_provider.dart';
import '../providers/page_index_provider.dart';
import '../config/app_ui_mode_config.dart';
import '../services/user_preferences_service.dart';
import '../l10n/l10n.dart';
import '../widgets/single_group_creation_dialog.dart';

class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SignUpFormState createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Email'),
            validator: (value) {
              if (value == null || !value.contains('@')) {
                return 'Invalid email';
              }
              return null;
            },
            onSaved: (value) {
              _email = value!;
            },
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Password'),
            obscureText: true,
            validator: (value) {
              if (value == null || value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            onSaved: (value) {
              _password = value!;
            },
          ),
          ElevatedButton(
            onPressed: _submitSignUp,
            child: const Text('Sign Up'),
          ),
          ElevatedButton(
            onPressed: _submitSignIn,
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSignUp() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await ref.read(authProvider).signUp(_email, _password);
        if (!mounted) return;

        // サインアップ後は必ずシングルモードに即設定（非同期の_syncUserProfileを待たない）
        AppUIModeSettings.setMode(AppUIMode.single);
        ref.read(appUIModeProvider.notifier).state = AppUIMode.single;
        await UserPreferencesService.saveAppUIMode(0);

        // シングルモードのグループ作成ダイアログを表示（新規ユーザーは常に表示）
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (_) => const _SingleGroupCreationPage(),
            ),
          );
        }

        if (!mounted) return;
        ref.read(pageIndexProvider.notifier).setPageIndex(0);
        Navigator.of(context).pop();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign Up Failed: $e')),
        );
      }
    }
  }

  Future<void> _submitSignIn() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await ref.read(authProvider).signIn(_email, _password);
        if (!mounted) return;
        ref.read(pageIndexProvider.notifier).setPageIndex(0);
        Navigator.of(context).pop();
      } catch (e) {
        // サインイン失敗時にサインアップ確認ダイアログを表示
        if (!mounted) return;
        _showSignUpConfirmationDialog();
      }
    }
  }

  Future<void> _showSignUpConfirmationDialog() async {
    final bool? shouldSignUp = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('アカウントが見つかりません'),
          content:
              Text('メールアドレス "$_email" のアカウントが見つかりませんでした。\n新しいアカウントを作成しますか？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('アカウント作成'),
            ),
          ],
        );
      },
    );

    if (shouldSignUp == true && mounted) {
      await _performSignUp();
    }
  }

  Future<void> _performSignUp() async {
    try {
      await ref.read(authProvider).signUp(_email, _password);
      if (!mounted) return;

      // サインアップ後は必ずシングルモードに即設定（非同期の_syncUserProfileを待たない）
      AppUIModeSettings.setMode(AppUIMode.single);
      ref.read(appUIModeProvider.notifier).state = AppUIMode.single;
      await UserPreferencesService.saveAppUIMode(0);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(texts.accountCreated)),
      );

      // シングルモードのグループ作成ダイアログを表示（新規ユーザーは常に表示）
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => const _SingleGroupCreationPage(),
          ),
        );
      }

      if (!mounted) return;
      ref.read(pageIndexProvider.notifier).setPageIndex(0);
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${texts.accountCreationFailed}: $e')),
      );
    }
  }
}

class _SingleGroupCreationPage extends StatelessWidget {
  const _SingleGroupCreationPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: Center(
          child: SingleGroupCreationDialog(),
        ),
      ),
    );
  }
}
