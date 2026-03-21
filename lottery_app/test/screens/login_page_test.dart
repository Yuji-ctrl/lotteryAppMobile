import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_app/screens/login_page.dart';
import 'package:lottery_app/services/api_service.dart';
import 'package:openapi/api.dart';

class FakeApiService extends ApiService {
  FakeApiService({
    this.loginResponse,
    this.signupResponse,
    this.loginError,
    this.signupError,
  });

  final AuthResponse? loginResponse;
  final AuthResponse? signupResponse;
  final Object? loginError;
  final Object? signupError;

  @override
  Future<AuthResponse> login({required String email, required String password}) async {
    if (loginError != null) {
      throw loginError!;
    }
    if (loginResponse != null) {
      return loginResponse!;
    }
    throw ApiException(500, 'login mock response is not set');
  }

  @override
  Future<AuthResponse> signup({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (signupError != null) {
      throw signupError!;
    }
    if (signupResponse != null) {
      return signupResponse!;
    }
    throw ApiException(500, 'signup mock response is not set');
  }
}

AuthResponse _authResponse() {
  return AuthResponse(
    accessToken: 'token-123',
    refreshToken: 'refresh-123',
    tokenType: 'Bearer',
    expiresIn: 3600,
    user: User(
      userId: 'user-1',
      displayName: 'tester',
      email: 'tester@example.com',
      createdAt: DateTime(2026, 1, 1),
    ),
  );
}

void main() {
  testWidgets('ログイン成功時に次画面へ遷移する', (tester) async {
    final apiService = FakeApiService(loginResponse: _authResponse());

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(apiService: apiService),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'ログイン'));
    await tester.pumpAndSettle();

    expect(find.text('Smart Kuji'), findsOneWidget);
    expect(find.text('はじめる'), findsOneWidget);
  });

  testWidgets('新規登録時にHTTP500をSnackBarで表示する', (tester) async {
    final apiService = FakeApiService(
      signupError: ApiException(500, 'internal server error'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(apiService: apiService),
      ),
    );

    await tester.tap(find.text('新規登録はこちら'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'test user');
    await tester.enterText(find.byType(TextField).at(1), 'user@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');

    await tester.tap(find.widgetWithText(ElevatedButton, '新規登録'));
    await tester.pump();

    expect(
      find.text('サーバー処理が未接続のため失敗しました（HTTP 500）。連携後に再度お試しください。'),
      findsOneWidget,
    );
  });
}
