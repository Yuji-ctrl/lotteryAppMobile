import 'package:openapi/api.dart';

class ApiClient {
  static final AuthApi authApi = AuthApi();
  static final StoresApi storesApi = StoresApi();
  static final LotteryApi lotteryApi = LotteryApi();
  static final PaymentsApi paymentsApi = PaymentsApi();

  /// 認証トークンを設定する
  static void setAuthToken(String token) {
    final bearerAuth = defaultApiClient.getAuthentication<HttpBearerAuth>('bearerAuth');
    if (bearerAuth != null) {
      bearerAuth.setAccessToken(token);
    }
  }

  /// 動作確認用のテストメソッド
  static Future<void> testConnection() async {
    try {
      print('--- API接続テスト開始 ---');
      final result = await authApi.getMe();
      print('getMe結果: $result');
    } catch (e) {
      print('APIテスト呼び出しでエラーが発生しました: $e');
    }
  }
}

