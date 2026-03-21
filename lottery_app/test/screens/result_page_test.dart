import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_app/screens/result_page.dart';
import 'package:lottery_app/services/api_service.dart';
import 'package:openapi/api.dart';

class FakeResultApiService extends ApiService {
  FakeResultApiService({
    this.results = const [],
    this.detail,
    this.listError,
    this.detailError,
  });

  final List<LotteryResult> results;
  final LotteryResultDetail? detail;
  final Object? listError;
  final Object? detailError;

  @override
  Future<List<LotteryResult>> fetchLotteryResults({
    int limit = 20,
    String? nextToken,
  }) async {
    if (listError != null) {
      throw listError!;
    }
    return results;
  }

  @override
  Future<LotteryResultDetail> fetchLotteryResultDetail({
    required String resultId,
  }) async {
    if (detailError != null) {
      throw detailError!;
    }
    if (detail != null) {
      return detail!;
    }
    throw ApiException(500, 'detail mock response is not set');
  }
}

void main() {
  testWidgets('結果APIが200のとき履歴と詳細を表示する', (tester) async {
    final api = FakeResultApiService(
      results: [
        LotteryResult(
          resultId: 'result-1',
          userId: 'user-1',
          storeId: 'store-1',
          prizeGrade: PrizeGrade.A,
          status: LotteryStatus.WON,
          paymentId: 'pay-1',
          createdAt: DateTime(2026, 3, 20, 12),
        ),
      ],
      detail: LotteryResultDetail(
        resultId: 'result-1',
        userId: 'user-1',
        storeId: 'store-1',
        prizeGrade: PrizeGrade.A,
        status: LotteryStatus.WON,
        paymentId: 'pay-1',
        createdAt: DateTime(2026, 3, 20, 12),
        prizeName: 'A賞フィギュア',
        idempotencyKey: null,
        store: Store(
          storeId: 'store-1',
          storeName: 'テスト店舗',
          address: 'Tokyo',
          latitude: 35.0,
          longitude: 139.0,
          geohash: 'xn76',
          isActive: true,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          resultName: 'A賞フィギュア',
          resultId: 'result-1',
          apiService: api,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('抽選履歴'), findsOneWidget);
    expect(find.text('結果詳細'), findsOneWidget);
    expect(find.text('景品: A賞フィギュア'), findsOneWidget);
    expect(find.text('店舗名: テスト店舗'), findsOneWidget);
  });

  testWidgets('履歴APIが500エラーのときSnackBarを表示する', (tester) async {
    final api = FakeResultApiService(
      listError: ApiException(500, 'Internal Server Error'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ResultPage(
          resultName: 'A賞フィギュア',
          apiService: api,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('抽選結果の取得に失敗しました（HTTP 500）。時間をおいて再度お試しください。'), findsWidgets);
    expect(find.text('再試行'), findsOneWidget);
  });
}
