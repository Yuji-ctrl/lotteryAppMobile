import 'package:flutter_test/flutter_test.dart';
import 'package:openapi/api.dart';

void main() {
  group('OpenAPI Client Tests', () {
    // APIクライアントのインスタンスを初期化
    // 必要に応じてベースURLをモックサーバーやローカルサーバーに変更できます
    final defaultClient = defaultApiClient;
    defaultClient.basePath = 'http://localhost:8080/v1'; // 例: ローカルサーバーのURL

    test('AuthApiインスタンスの作成と設定のテスト', () {
      final authApi = AuthApi(defaultClient);
      expect(authApi, isNotNull);
    });
  });
}
