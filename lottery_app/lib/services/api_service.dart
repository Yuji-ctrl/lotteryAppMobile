import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:openapi/api.dart';

class ApiService {
  static const String _storesAllFallbackBasePath =
      'https://dzqidy2gl8.execute-api.ap-northeast-1.amazonaws.com/Prod';
  static const String _storesAllPath = '/stores-all';

  ApiService({
    AuthApi? authApi,
    StoresApi? storesApi,
    LotteryApi? lotteryApi,
    PaymentsApi? paymentsApi,
  }) : _authApi = authApi ?? AuthApi(),
       _storesApi = storesApi ?? StoresApi(),
       _lotteryApi = lotteryApi ?? LotteryApi(),
       _paymentsApi = paymentsApi ?? PaymentsApi() {
    _storesAllApiClient = _buildStoresAllApiClient(_storesApi.apiClient);
  }

  final AuthApi _authApi;
  final StoresApi _storesApi;
  final LotteryApi _lotteryApi;
  final PaymentsApi _paymentsApi;
  late final ApiClient _storesAllApiClient;

  static ApiClient _buildStoresAllApiClient(ApiClient storesApiClient) {
    final client = ApiClient(
      basePath: _resolveStoresAllBasePath(storesApiClient.basePath),
      authentication: storesApiClient.authentication,
    )..client = storesApiClient.client;

    client.defaultHeaderMap.addAll(storesApiClient.defaultHeaderMap);
    return client;
  }

  static String _resolveStoresAllBasePath(String currentBasePath) {
    final normalized = currentBasePath.trim();
    if (normalized.isEmpty) {
      return _storesAllFallbackBasePath;
    }

    final uri = Uri.tryParse(normalized);
    if (uri == null || uri.host == 'api.example.com') {
      return _storesAllFallbackBasePath;
    }

    return normalized;
  }

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
    final response = await _storesApi.listStoreInventories(storeId);
    if (response == null) {
      throw ApiException(500, '景品在庫の取得結果が空でした');
    }
    return response.items;
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
      final response = await _storesAllApiClient.invokeAPI(
        _storesAllPath,
        'GET',
        <QueryParam>[],
        null,
        <String, String>{},
        <String, String>{},
        null,
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiException(response.statusCode, response.body);
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw ApiException(500, '店舗一覧の取得結果の形式が不正でした');
      }

      final storesResponse = ListStores200Response.fromJson(decoded);
      if (storesResponse == null) {
        throw ApiException(500, '店舗一覧の取得結果が空でした');
      }
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
    final response = await _paymentsApi.createPayment(
      CreatePaymentRequest(
        amount: amount,
        currency: currency,
        metadata: metadata,
      ),
    );
    if (response == null) {
      throw ApiException(500, '決済開始結果を取得できませんでした');
    }
    return response;
  }

  Future<Payment> getPaymentById({required String paymentId}) async {
    final response = await _paymentsApi.getPaymentById(paymentId);
    if (response == null) {
      throw ApiException(500, '決済状態を取得できませんでした');
    }
    return response;
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
