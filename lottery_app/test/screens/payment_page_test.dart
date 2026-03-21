import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_app/screens/payment_page.dart';
import 'package:lottery_app/services/api_service.dart';
import 'package:openapi/api.dart';

class FakePaymentApiService extends ApiService {
  FakePaymentApiService({
    this.createPaymentError,
    this.initialPaymentStatus = PaymentStatusEnum.CREATED,
    this.pollingStatuses = const [PaymentStatusEnum.PAID],
  });

  final Object? createPaymentError;
  final PaymentStatusEnum initialPaymentStatus;
  final List<PaymentStatusEnum> pollingStatuses;
  int pollingCount = 0;

  @override
  Future<Payment> createPayment({
    required int amount,
    String currency = 'JPY',
    Map<String, String> metadata = const {},
  }) async {
    if (createPaymentError != null) {
      throw createPaymentError!;
    }

    return Payment(
      paymentId: 'pay-1',
      status: initialPaymentStatus,
      amount: amount,
      currency: currency,
      createdAt: DateTime(2026, 3, 20),
      paidAt: null,
    );
  }

  @override
  Future<Payment> getPaymentById({required String paymentId}) async {
    final index = pollingCount < pollingStatuses.length
        ? pollingCount
        : pollingStatuses.length - 1;
    final status = pollingStatuses[index];
    pollingCount += 1;

    return Payment(
      paymentId: paymentId,
      status: status,
      amount: 700,
      currency: 'JPY',
      createdAt: DateTime(2026, 3, 20),
      paidAt: status == PaymentStatusEnum.PAID
          ? DateTime(2026, 3, 20, 12)
          : null,
    );
  }
}

void main() {
  testWidgets('決済成功時に抽選アニメーション画面へ遷移する', (tester) async {
    final api = FakePaymentApiService(
      initialPaymentStatus: PaymentStatusEnum.PENDING,
      pollingStatuses: const [
        PaymentStatusEnum.PENDING,
        PaymentStatusEnum.PAID,
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(
          kujiName: 'テストくじ',
          resultName: 'A賞フィギュア',
          apiService: api,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, '決済を確定してくじを引く'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    expect(find.text('当たり'), findsOneWidget);
    expect(api.pollingCount, greaterThanOrEqualTo(1));
  });

  testWidgets('決済開始が500エラーのときSnackBarを表示し復帰する', (tester) async {
    final api = FakePaymentApiService(
      createPaymentError: ApiException(500, 'Internal Server Error'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: PaymentPage(
          kujiName: 'テストくじ',
          resultName: 'A賞フィギュア',
          apiService: api,
        ),
      ),
    );

    await tester.tap(find.widgetWithText(ElevatedButton, '決済を確定してくじを引く'));
    await tester.pumpAndSettle();

    expect(find.text('決済処理に失敗しました（HTTP 500）。時間をおいて再度お試しください。'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, '決済を確定してくじを引く'), findsOneWidget);
  });
}
