import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart';

import 'package:lottery_app/services/api_service.dart';

class _FakeStoresApi extends StoresApi {
  _FakeStoresApi({this.response});

  ListStores200Response? response;
  double? requestedLat;
  double? requestedLng;
  int? requestedRadius;

  @override
  Future<ListStores200Response?> listStores(
    double lat,
    double lng,
    int radius,
  ) async {
    requestedLat = lat;
    requestedLng = lng;
    requestedRadius = radius;
    return response;
  }
}

class _FakePaymentsApi extends PaymentsApi {
  _FakePaymentsApi({this.createResponse, this.getByIdResponse});

  Payment? createResponse;
  Payment? getByIdResponse;
  CreatePaymentRequest? requestedCreateBody;
  String? requestedPaymentId;

  @override
  Future<Payment?> createPayment(
    CreatePaymentRequest createPaymentRequest,
  ) async {
    requestedCreateBody = createPaymentRequest;
    return createResponse;
  }

  @override
  Future<Payment?> getPaymentById(String paymentId) async {
    requestedPaymentId = paymentId;
    return getByIdResponse;
  }
}

class _FakeLotteryApi extends LotteryApi {
  _FakeLotteryApi({this.listResponse, this.detailResponse});

  ListLotteryResults200Response? listResponse;
  LotteryResultDetail? detailResponse;
  int? requestedLimit;
  String? requestedNextToken;
  String? requestedResultId;

  @override
  Future<ListLotteryResults200Response?> listLotteryResults({
    int? limit,
    String? nextToken,
  }) async {
    requestedLimit = limit;
    requestedNextToken = nextToken;
    return listResponse;
  }

  @override
  Future<LotteryResultDetail?> getLotteryResultById(String resultId) async {
    requestedResultId = resultId;
    return detailResponse;
  }
}

void main() {
  group('ApiService.parseApiExceptionMessage', () {
    test('returns message field when API error body is JSON', () {
      final error = ApiException(
        422,
        '{"code":"OUTSIDE_AREA","message":"店舗外からの抽選はできません"}',
      );

      final message = ApiService.parseApiExceptionMessage(error);

      expect(message, '店舗外からの抽選はできません');
    });

    test('returns plain text when API error body is not JSON', () {
      final error = ApiException(500, 'Internal Server Error');

      final message = ApiService.parseApiExceptionMessage(error);

      expect(message, 'Internal Server Error');
    });
  });

  group('ApiService.fetchNearbyStores', () {
    test('returns only active stores and forwards query params', () async {
      final fakeStoresApi = _FakeStoresApi(
        response: ListStores200Response(
          items: [
            Store(
              storeId: 'store-1',
              storeName: 'Active Store',
              address: 'Tokyo',
              latitude: 35.0,
              longitude: 139.0,
              geohash: 'xn76',
              isActive: true,
            ),
            Store(
              storeId: 'store-2',
              storeName: 'Inactive Store',
              address: 'Tokyo',
              latitude: 35.1,
              longitude: 139.1,
              geohash: 'xn77',
              isActive: false,
            ),
          ],
        ),
      );
      final service = ApiService(storesApi: fakeStoresApi);

      final stores = await service.fetchNearbyStores(
        latitude: 35.123,
        longitude: 139.456,
        searchRadiusMeter: 1200,
      );

      expect(fakeStoresApi.requestedLat, 35.123);
      expect(fakeStoresApi.requestedLng, 139.456);
      expect(fakeStoresApi.requestedRadius, 1200);
      expect(stores.length, 1);
      expect(stores.first.storeId, 'store-1');
    });

    test('throws ApiException when response is null', () async {
      final service = ApiService(storesApi: _FakeStoresApi(response: null));

      expect(
        () => service.fetchNearbyStores(latitude: 35.0, longitude: 139.0),
        throwsA(
          isA<ApiException>()
              .having((e) => e.code, 'code', 500)
              .having((e) => e.message, 'message', '店舗一覧の取得結果が空でした'),
        ),
      );
    });
  });

  group('ApiService.userMessageFromException', () {
    test('maps 401/403 to re-login message', () {
      final message = ApiService.userMessageFromException(
        ApiException(401, 'unauthorized'),
      );

      expect(message, '認証エラーが発生しました。再ログインしてください。');
    });

    test('maps 409 to conflict message', () {
      final message = ApiService.userMessageFromException(
        ApiException(409, 'conflict'),
      );

      expect(message, '在庫情報が更新されました。画面を更新して再度お試しください。');
    });

    test('maps 422 to geofence message', () {
      final message = ApiService.userMessageFromException(
        ApiException(422, 'outside area'),
      );

      expect(message, '店舗外からの抽選はできません。店舗付近で再度お試しください。');
    });

    test('falls back to default message for unknown errors', () {
      final message = ApiService.userMessageFromException(Exception('boom'));

      expect(message, '処理に失敗しました。通信環境を確認して再度お試しください。');
    });
  });

  group('ApiService payment methods', () {
    test('createPayment forwards request and returns payment', () async {
      final fakePaymentsApi = _FakePaymentsApi(
        createResponse: Payment(
          paymentId: 'pay-1',
          status: PaymentStatusEnum.CREATED,
          amount: 700,
          currency: 'JPY',
          createdAt: DateTime(2026, 3, 20),
          paidAt: null,
        ),
      );
      final service = ApiService(paymentsApi: fakePaymentsApi);

      final payment = await service.createPayment(
        amount: 700,
        currency: 'JPY',
        metadata: const {'source': 'test'},
      );

      expect(fakePaymentsApi.requestedCreateBody?.amount, 700);
      expect(fakePaymentsApi.requestedCreateBody?.currency, 'JPY');
      expect(fakePaymentsApi.requestedCreateBody?.metadata?['source'], 'test');
      expect(payment.paymentId, 'pay-1');
    });

    test('getPaymentById forwards paymentId and returns payment', () async {
      final fakePaymentsApi = _FakePaymentsApi(
        getByIdResponse: Payment(
          paymentId: 'pay-2',
          status: PaymentStatusEnum.PAID,
          amount: 700,
          currency: 'JPY',
          createdAt: DateTime(2026, 3, 20),
          paidAt: DateTime(2026, 3, 20, 12),
        ),
      );
      final service = ApiService(paymentsApi: fakePaymentsApi);

      final payment = await service.getPaymentById(paymentId: 'pay-2');

      expect(fakePaymentsApi.requestedPaymentId, 'pay-2');
      expect(payment.status, PaymentStatusEnum.PAID);
    });
  });

  group('ApiService lottery result methods', () {
    test('fetchLotteryResults forwards params and returns list', () async {
      final fakeLotteryApi = _FakeLotteryApi(
        listResponse: ListLotteryResults200Response(
          items: [
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
          nextToken: null,
        ),
      );
      final service = ApiService(lotteryApi: fakeLotteryApi);

      final results = await service.fetchLotteryResults(
        limit: 30,
        nextToken: 'token-1',
      );

      expect(fakeLotteryApi.requestedLimit, 30);
      expect(fakeLotteryApi.requestedNextToken, 'token-1');
      expect(results.length, 1);
      expect(results.first.resultId, 'result-1');
    });

    test('fetchLotteryResultDetail forwards resultId and returns detail', () async {
      final fakeLotteryApi = _FakeLotteryApi(
        detailResponse: LotteryResultDetail(
          resultId: 'result-1',
          userId: 'user-1',
          storeId: 'store-1',
          prizeGrade: PrizeGrade.A,
          status: LotteryStatus.WON,
          paymentId: 'pay-1',
          createdAt: DateTime(2026, 3, 20, 12),
          prizeName: 'A賞フィギュア',
          idempotencyKey: null,
          store: null,
        ),
      );
      final service = ApiService(lotteryApi: fakeLotteryApi);

      final detail = await service.fetchLotteryResultDetail(resultId: 'result-1');

      expect(fakeLotteryApi.requestedResultId, 'result-1');
      expect(detail.prizeName, 'A賞フィギュア');
    });

    test('lotteryResultUserMessageFromException maps 500 correctly', () {
      final message = ApiService.lotteryResultUserMessageFromException(
        ApiException(500, 'Internal Server Error'),
      );

      expect(message, '抽選結果の取得に失敗しました（HTTP 500）。時間をおいて再度お試しください。');
    });
  });
}
