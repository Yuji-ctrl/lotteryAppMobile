import 'package:flutter/material.dart';
import 'animation_page.dart';

class PaymentPage extends StatefulWidget {
  final String kujiName;
  final String resultName; // 既に決まった抽選結果を引き継ぐ
  final String? resultId;

  const PaymentPage({
    super.key,
    required this.kujiName,
    required this.resultName,
    this.resultId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const int _paymentAmount = 700;
  static const Duration _mockProcessingDuration = Duration(seconds: 2);

  int _selectedMethod = 0;
  bool _isSubmitting = false;
  String? _progressLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('お支払い')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '購入内容',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.grey[100],
              title: Text(widget.kujiName),
              trailing: Text(
                '¥$_paymentAmount',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              '支払い方法',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            RadioListTile<int>(
              value: 0,
              groupValue: _selectedMethod,
              onChanged: _isSubmitting
                  ? null
                  : (v) => setState(() => _selectedMethod = v ?? 0),
              title: const Text('クレジットカード'),
            ),
            RadioListTile<int>(
              value: 1,
              groupValue: _selectedMethod,
              onChanged: _isSubmitting
                  ? null
                  : (v) => setState(() => _selectedMethod = v ?? 0),
              title: const Text('PayPay'),
            ),
            if (_isSubmitting) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _progressLabel ?? '決済処理中です...',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSubmitting ? null : _onTapConfirm,
                child: Text(
                  _isSubmitting ? '決済処理中...' : '決済を確定してくじを引く',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTapConfirm() async {
    setState(() {
      _isSubmitting = true;
      _progressLabel = '決済をシミュレーションしています...';
    });

    try {
      await Future<void>.delayed(_mockProcessingDuration);
      if (!mounted) return;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LotteryAnimationPage(
            resultName: widget.resultName,
            resultId: widget.resultId,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('決済シミュレーションに失敗しました。再度お試しください。');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _progressLabel = null;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
