import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:openapi/api.dart';

class ApiService {
  static const String _defaultAuthBasePath =
      'https://dzqidy2gl8.execute-api.ap-northeast-1.amazonaws.com/Prod';
  static const String _defaultStoresBasePath =
      'https://dzqidy2gl8.execute-api.ap-northeast-1.amazonaws.com/Prod';
  static const String _defaultLotteryBasePath =
      'https://z2pkcs0rc0.execute-api.ap-northeast-1.amazonaws.com/Prod';

  ApiService({
    String authBasePath = _defaultAuthBasePath,
    String storesBasePath = _defaultStoresBasePath,
    String lotteryBasePath = _defaultLotteryBasePath,
    AuthApi? authApi,
    StoresApi? storesApi,
    LotteryApi? lotteryApi,
  }) {
    _authApi = authApi ?? AuthApi(ApiClient(basePath: authBasePath));
    _storesApi = storesApi ?? StoresApi(ApiClient(basePath: storesBasePath));
    _lotteryApi =
        lotteryApi ?? LotteryApi(ApiClient(basePath: lotteryBasePath));
  }

  late final AuthApi _authApi;
  late final StoresApi _storesApi;
  late final LotteryApi _lotteryApi;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _authApi.login(
      LoginRequest(email: email, password: password),
    );
    if (response == null) {
      throw ApiException(500, 'ログイン結果を取得できませんでした');
    }
    return response;
  }

  Future<AuthResponse> signup({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final response = await _authApi.signup(
      SignUpRequest(displayName: displayName, email: email, password: password),
    );
    if (response == null) {
      throw ApiException(500, 'ユーザー登録結果を取得できませんでした');
    }
    return response;
  }

  Future<List<Inventory>> fetchStoreInventories({
    required String storeId,
  }) async {
    final response = await _storesApi.apiClient.invokeAPI(
      '/store/$storeId/inventorie',
      'GET',
      <QueryParam>[],
      null,
      <String, String>{},
      <String, String>{},
      null,
    );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, response.body);
    }
    if (response.body.isEmpty || response.statusCode == HttpStatus.noContent) {
      throw ApiException(500, '景品在庫の取得結果が空でした');
    }
    final normalizedBody = _normalizeInventoryResponseBody(response.body);
    final parsed =
        await _storesApi.apiClient.deserializeAsync(
              normalizedBody,
              'ListStoreInventories200Response',
            )
            as ListStoreInventories200Response;
    return parsed.items;
  }

  String _normalizeInventoryResponseBody(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) {
      return rawBody;
    }

    final normalized = Map<String, dynamic>.from(decoded);
    _moveKeyIfNeeded(normalized, 'store_id', 'storeId');

    final items = normalized['items'];
    if (items is List) {
      normalized['items'] = items
          .map((item) {
            if (item is! Map<String, dynamic>) {
              return item;
            }

            final row = Map<String, dynamic>.from(item);
            _moveKeyIfNeeded(row, 'store_id', 'storeId');
            _moveKeyIfNeeded(row, 'prize_grade', 'prizeGrade');
            _moveKeyIfNeeded(row, 'prize_name', 'prizeName');
            _moveKeyIfNeeded(row, 'total_count', 'totalCount');
            _moveKeyIfNeeded(row, 'remaining_count', 'remainingCount');
            return row;
          })
          .toList(growable: false);
    }

    return jsonEncode(normalized);
  }

  void _moveKeyIfNeeded(Map<String, dynamic> source, String from, String to) {
    if (!source.containsKey(from) || source.containsKey(to)) {
      return;
    }
    source[to] = source[from];
  }

  Future<List<Store>> fetchNearbyStores({
    required double latitude,
    required double longitude,
    int searchRadiusMeter = 1000,
  }) async {
    final response = await _storesApi.listStores(
      latitude,
      longitude,
      searchRadiusMeter,
    );
    if (response == null) {
      throw ApiException(500, '店舗一覧の取得結果が空でした');
    }

    return response.items
        .where((store) => store.isActive)
        .toList(growable: false);
  }

  Future<List<Store>> fetchAllStores() async {
    try {
      final response = await _storesApi.storesAllGetWithHttpInfo();
      if (response.statusCode >= HttpStatus.badRequest) {
        throw ApiException(response.statusCode, response.body);
      }
      if (response.body.isEmpty ||
          response.statusCode == HttpStatus.noContent) {
        throw ApiException(500, '店舗一覧の取得結果が空でした');
      }

      final storesResponse =
          await _storesApi.apiClient.deserializeAsync(
                response.body,
                'ListStores200Response',
              )
              as ListStores200Response;
      return storesResponse.items
          .where((store) => store.isActive)
          .toList(growable: false);
    } on ApiException {
      rethrow;
    } on FormatException {
      throw ApiException(500, '店舗一覧の取得結果の形式が不正でした');
    } on Object catch (error, trace) {
      throw ApiException.withInner(
        500,
        '店舗一覧の取得処理で予期しないエラーが発生しました',
        error is Exception ? error : Exception(error.toString()),
        trace,
      );
    }
  }

  Future<String> resolveStoreId({
    String? preferredStoreId,
    required String shopName,
    required double latitude,
    required double longitude,
    int searchRadiusMeter = 1000,
  }) async {
    if (preferredStoreId != null && preferredStoreId.isNotEmpty) {
      return preferredStoreId;
    }

    final stores = await _storesApi.listStores(
      latitude,
      longitude,
      searchRadiusMeter,
    );
    final found = stores?.items
        .where((store) => store.storeName == shopName)
        .firstOrNull;
    if (found != null) {
      return found.storeId;
    }

    throw ApiException(404, '対象店舗のstoreIdが見つかりませんでした');
  }

  Future<LotteryDrawResponse> drawLottery({
    required String storeId,
    required double latitude,
    required double longitude,
    required String paymentId,
    required String idempotencyKey,
  }) async {
    final request = LotteryDrawRequest(
      storeId: storeId,
      latitude: latitude,
      longitude: longitude,
      paymentId: paymentId,
      idempotencyKey: idempotencyKey,
    );

    final response = await _lotteryApi.drawLottery(request);
    if (response == null) {
      throw ApiException(500, '抽選結果を取得できませんでした');
    }
    return response;
  }

  Future<List<LotteryResult>> fetchLotteryResults({
    int limit = 20,
    String? nextToken,
  }) async {
    final response = await _lotteryApi.listLotteryResults(
      limit: limit,
      nextToken: nextToken,
    );
    if (response == null) {
      throw ApiException(500, '抽選履歴の取得結果が空でした');
    }
    return response.items;
  }

  Future<LotteryResultDetail> fetchLotteryResultDetail({
    required String resultId,
  }) async {
    final response = await _lotteryApi.getLotteryResultById(resultId);
    if (response == null) {
      throw ApiException(500, '抽選結果詳細の取得結果が空でした');
    }
    return response;
  }

  Future<Payment> createPayment({
    required int amount,
    String currency = 'JPY',
    Map<String, String> metadata = const {},
  }) async {
    final now = DateTime.now();
    return Payment(
      paymentId: 'mock-payment-${now.microsecondsSinceEpoch}',
      status: PaymentStatusEnum.PAID,
      amount: amount,
      currency: currency,
      createdAt: now,
      paidAt: now,
    );
  }

  Future<Payment> getPaymentById({required String paymentId}) async {
    final now = DateTime.now();
    return Payment(
      paymentId: paymentId,
      status: PaymentStatusEnum.PAID,
      amount: 700,
      currency: 'JPY',
      createdAt: now,
      paidAt: now,
    );
  }

  static String userMessageFromException(Object error) {
    if (error is ApiException) {
      final code = error.code;
      if (code == 401 || code == 403) {
        return '認証エラーが発生しました。再ログインしてください。';
      }
      if (code == 409) {
        return '在庫情報が更新されました。画面を更新して再度お試しください。';
      }
      if (code == 422) {
        return '店舗外からの抽選はできません。店舗付近で再度お試しください。';
      }

      final parsed = parseApiExceptionMessage(error);
      if (parsed.isNotEmpty) {
        return '抽選に失敗しました: $parsed';
      }

      return '抽選に失敗しました（HTTP $code）。しばらくして再度お試しください。';
    }

    return '処理に失敗しました。通信環境を確認して再度お試しください。';
  }

  static String inventoryUserMessageFromException(Object error) {
    if (error is ApiException) {
      final code = error.code;
      if (code == 404) {
        return '対象店舗の在庫情報が見つかりません。店舗情報を確認してください。';
      }
      if (code == 500) {
        return '在庫情報の取得に失敗しました（HTTP 500）。時間をおいて再度お試しください。';
      }

      final parsed = parseApiExceptionMessage(error);
      if (parsed.isNotEmpty) {
        return '在庫情報の取得に失敗しました: $parsed';
      }

      return '在庫情報の取得に失敗しました（HTTP $code）。時間をおいて再度お試しください。';
    }

    return '在庫情報の取得に失敗しました。通信環境を確認して再度お試しください。';
  }

  static String parseApiExceptionMessage(ApiException error) {
    final raw = error.message?.trim() ?? '';
    if (raw.isEmpty) {
      return '';
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } on FormatException {
      // Ignore non-JSON bodies and use raw string instead.
    }

    return raw;
  }

  static String authUserMessageFromException(
    Object error, {
    required bool isSignup,
  }) {
    final action = isSignup ? '新規登録' : 'ログイン';

    if (error is ApiException) {
      final code = error.code;
      if (code == 400 || code == 422) {
        return '$actionに失敗しました。入力内容を確認してください。';
      }
      if (code == 401 || code == 403) {
        return '$actionに失敗しました。認証情報を確認してください。';
      }
      if (code == 409) {
        return 'このメールアドレスは既に利用されています。';
      }
      if (code == 500) {
        return 'サーバー処理が未接続のため失敗しました（HTTP 500）。連携後に再度お試しください。';
      }

      final parsed = parseApiExceptionMessage(error);
      if (parsed.isNotEmpty) {
        return '$actionに失敗しました: $parsed';
      }

      return '$actionに失敗しました（HTTP $code）。しばらくして再度お試しください。';
    }

    return '$actionに失敗しました。通信環境を確認して再度お試しください。';
  }

  static String paymentUserMessageFromException(Object error) {
    if (error is ApiException) {
      final code = error.code;
      if (code == 400 || code == 422) {
        return '決済情報が不正です。入力内容を確認してください。';
      }
      if (code == 401 || code == 403) {
        return '認証エラーが発生しました。再ログインしてください。';
      }
      if (code == 404) {
        return '決済情報が見つかりません。再度決済をお試しください。';
      }
      if (code == 500) {
        return '決済処理に失敗しました（HTTP 500）。時間をおいて再度お試しください。';
      }

      final parsed = parseApiExceptionMessage(error);
      if (parsed.isNotEmpty) {
        return '決済に失敗しました: $parsed';
      }

      return '決済に失敗しました（HTTP $code）。しばらくして再度お試しください。';
    }

    return '決済に失敗しました。通信環境を確認して再度お試しください。';
  }

  static String lotteryResultUserMessageFromException(Object error) {
    if (error is ApiException) {
      final code = error.code;
      if (code == 401 || code == 403) {
        return '認証エラーが発生しました。再ログインしてください。';
      }
      if (code == 404) {
        return '抽選結果が見つかりませんでした。';
      }
      if (code == 500) {
        return '抽選結果の取得に失敗しました（HTTP 500）。時間をおいて再度お試しください。';
      }

      final parsed = parseApiExceptionMessage(error);
      if (parsed.isNotEmpty) {
        return '抽選結果の取得に失敗しました: $parsed';
      }

      return '抽選結果の取得に失敗しました（HTTP $code）。しばらくして再度お試しください。';
    }

    return '抽選結果の取得に失敗しました。通信環境を確認して再度お試しください。';
  }
}
