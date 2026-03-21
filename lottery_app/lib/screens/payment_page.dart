import 'package:flutter/material.dart';
import 'package:openapi/api.dart' show ApiException, Payment, PaymentStatusEnum;

import '../services/api_service.dart';
import 'animation_page.dart';

class PaymentPage extends StatefulWidget {
  final String kujiName;
  final String resultName; // 既に決まった抽選結果を引き継ぐ
  final String? resultId;
  final ApiService? apiService;

  const PaymentPage({
    super.key,
    required this.kujiName,
    required this.resultName,
    this.resultId,
    this.apiService,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const int _paymentAmount = 700;
  static const Duration _pollInterval = Duration(seconds: 1);
  static const int _maxPollingCount = 8;

  late final ApiService _apiService;
  int _selectedMethod = 0;
  bool _isSubmitting = false;
  String? _progressLabel;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
  }

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
              trailing: const Text(
                '¥700',
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
      _progressLabel = '決済を開始しています...';
    });

    try {
      final payment = await _apiService.createPayment(
        amount: _paymentAmount,
        currency: 'JPY',
        metadata: {
          'kujiName': widget.kujiName,
          'paymentMethod': _selectedMethod == 0 ? 'credit_card' : 'paypay',
        },
      );
      if (!mounted) return;

      final completedPayment = await _waitForPaymentCompletion(payment);
      if (!mounted) return;

      if (!_isPaymentPaid(completedPayment.status)) {
        throw ApiException(500, '決済が完了しませんでした。しばらくしてから再度お試しください。');
      }

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              LotteryAnimationPage(
                resultName: widget.resultName,
                resultId: widget.resultId,
              ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(ApiService.paymentUserMessageFromException(e));
    } catch (_) {
      if (!mounted) return;
      _showErrorSnackBar('決済処理に失敗しました。通信環境を確認して再度お試しください。');
    } finally {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _progressLabel = null;
      });
    }
  }

  Future<Payment> _waitForPaymentCompletion(Payment initialPayment) async {
    var latest = initialPayment;
    if (_isTerminalPaymentStatus(latest.status)) {
      return latest;
    }

    for (var i = 0; i < _maxPollingCount; i++) {
      if (!mounted) break;
      setState(() {
        _progressLabel = '決済結果を確認中... (${i + 1}/$_maxPollingCount)';
      });

      await Future<void>.delayed(_pollInterval);
      latest = await _apiService.getPaymentById(paymentId: latest.paymentId);
      if (_isTerminalPaymentStatus(latest.status)) {
        return latest;
      }
    }

    return latest;
  }

  bool _isPaymentPaid(PaymentStatusEnum status) =>
      status == PaymentStatusEnum.PAID;

  bool _isTerminalPaymentStatus(PaymentStatusEnum status) {
    return status == PaymentStatusEnum.PAID ||
        status == PaymentStatusEnum.FAILED ||
        status == PaymentStatusEnum.CANCELED;
  }

  void _showErrorSnackBar(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
