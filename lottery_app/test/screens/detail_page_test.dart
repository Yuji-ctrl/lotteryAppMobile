import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_app/models/kuji_status.dart';
import 'package:lottery_app/screens/detail_page.dart';
import 'package:lottery_app/services/api_service.dart';
import 'package:openapi/api.dart';

class FakeDetailApiService extends ApiService {
  FakeDetailApiService({
    this.inventories = const [],
    this.drawResponse,
    this.inventoryError,
    this.drawError,
  });

  final List<Inventory> inventories;
  final LotteryDrawResponse? drawResponse;
  final Object? inventoryError;
  final Object? drawError;

  @override
  Future<String> resolveStoreId({
    String? preferredStoreId,
    required String shopName,
    required double latitude,
    required double longitude,
    int searchRadiusMeter = 1000,
  }) async {
    return preferredStoreId ?? 'store-1';
  }

  @override
  Future<List<Inventory>> fetchStoreInventories({required String storeId}) async {
    if (inventoryError != null) {
      throw inventoryError!;
    }
    return inventories;
  }

  @override
  Future<LotteryDrawResponse> drawLottery({
    required String storeId,
    required double latitude,
    required double longitude,
    required String paymentId,
    required String idempotencyKey,
  }) async {
    if (drawError != null) {
      throw drawError!;
    }
    if (drawResponse != null) {
      return drawResponse!;
    }
    throw ApiException(500, 'draw mock response is not set');
  }
}

KujiStatus _status() {
  return KujiStatus(
    storeId: 'store-1',
    shopName: 'テスト店舗',
    kujiName: 'テストくじ',
    latitude: 35.0,
    longitude: 139.0,
  );
}

void main() {
  testWidgets('抽選成功時に支払い画面へ遷移する', (tester) async {
    final api = FakeDetailApiService(
      inventories: [
        Inventory(
          storeId: 'store-1',
          prizeGrade: PrizeGrade.A,
          prizeName: 'A賞フィギュア',
          totalCount: 10,
          remainingCount: 5,
          version: 1,
        ),
      ],
      drawResponse: LotteryDrawResponse(
        resultId: 'result-1',
        status: LotteryStatus.WON,
        prizeGrade: PrizeGrade.A,
        prizeName: 'A賞フィギュア',
        message: '抽選成功',
        createdAt: DateTime(2026, 3, 20),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: KujiDetailPage(status: _status(), apiService: api),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'くじを引く'));
    await tester.pumpAndSettle();

    expect(find.text('お支払い'), findsOneWidget);
  });

  testWidgets('抽選APIが500エラーのときSnackBarを表示する', (tester) async {
    final api = FakeDetailApiService(
      inventories: [
        Inventory(
          storeId: 'store-1',
          prizeGrade: PrizeGrade.B,
          prizeName: 'B賞ポスター',
          totalCount: 10,
          remainingCount: 2,
          version: 1,
        ),
      ],
      drawError: ApiException(500, 'Internal Server Error'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: KujiDetailPage(status: _status(), apiService: api),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'くじを引く'));
    await tester.pumpAndSettle();

    expect(find.text('抽選に失敗しました: Internal Server Error'), findsWidgets);
  });

  testWidgets('在庫取得APIが500エラーのときSnackBarを表示する', (tester) async {
    final api = FakeDetailApiService(
      inventoryError: ApiException(500, 'Internal Server Error'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: KujiDetailPage(status: _status(), apiService: api),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('在庫情報の取得に失敗しました（HTTP 500）。時間をおいて再度お試しください。'), findsWidgets);
  });
}
