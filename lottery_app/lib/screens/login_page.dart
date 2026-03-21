import 'package:flutter/material.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _displayNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSignupMode = false;
  bool _isSubmitting = false;
  String? _authToken;

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submitAuth() async {
    final displayName = _displayNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (_isSignupMode && displayName.isEmpty) {
      _showMessage('表示名を入力してください');
      return;
    }
    if (email.isEmpty || password.isEmpty) {
      _showMessage('メールアドレスとパスワードを入力してください');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = await _mockAuthenticate(
        displayName: displayName,
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        _authToken = token;
      });

      _showMessage(_isSignupMode ? '新規登録に成功しました' : 'ログインに成功しました');

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (_) {
      if (!mounted) return;
      final action = _isSignupMode ? '新規登録' : 'ログイン';
      _showMessage('$actionに失敗しました。通信環境を確認して再度お試しください。');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<String> _mockAuthenticate({
    required String displayName,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final mode = _isSignupMode ? 'signup' : 'login';
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'mock-$mode-${email.hashCode}-${password.hashCode}-$timestamp';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final canSwitchMode = !_isSubmitting;

    return Scaffold(
      appBar: AppBar(title: Text(_isSignupMode ? '新規登録' : 'ログイン')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.shopping_bag_outlined,
              size: 80,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 20),
            const Text(
              'ちぇっくじ！へようこそ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            if (_isSignupMode) ...[
              TextField(
                controller: _displayNameController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: '表示名',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _emailController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'メールアドレス',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              enabled: !_isSubmitting,
              decoration: const InputDecoration(
                labelText: 'パスワード',
                border: OutlineInputBorder(),
              ),
              obscureText: true, // パスワードを隠す
            ),
            const SizedBox(height: 24),
            if (_authToken != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '認証トークン取得済み',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitAuth,
                child: Text(
                  _isSubmitting ? '送信中...' : (_isSignupMode ? '新規登録' : 'ログイン'),
                ),
              ),
            ),
            TextButton(
              onPressed: canSwitchMode
                  ? () {
                      setState(() {
                        _isSignupMode = !_isSignupMode;
                      });
                    }
                  : null,
              child: Text(_isSignupMode ? 'ログインはこちら' : '新規登録はこちら'),
            ),
          ],
        ),
      ),
    );
  }
}
