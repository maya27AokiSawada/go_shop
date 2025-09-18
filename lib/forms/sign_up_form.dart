import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/page_index_provider.dart';
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
      try{
        await ref.read(authProvider).signUp(_email, _password);
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign In Failed: $e')),
        );
      }
    }
  }
}
