# ちぇっくじ！！！

## Project Overview
「~~一番くじ~~をDXする」をコンセプトにモバイルアプリを製作しました。  
（ユーザー側のメリット）家にいながら近隣店舗の残り枚数を確認できる  
（お店側のメリット）面倒なアナログベースのくじ管理から解放される  
紙の~~一番くじ~~最大の特長である、めくるときのぺリぺリ感を演出することを目指しました。（リッチなアニメーションを効果音を制作中）  
フロントエンドにFlutterを、バックエンドにAWSを使用しました。（イベント限定プラン使用のため現在は停止中）  
Progateハッカソン powered by AWS（2026/03/10-21）で制作  
https://progate.connpass.com/event/379252/

## Repository Structure
```
root/
├── lib/                # Contains Flutter source files
│   ├── main.dart      # Entry point of the application
│   ├── screens/       # Contains different screens of the app
│   ├── widgets/       # Reusable widgets used across the app
│   └── services/      # Services for fetching lottery data
├── test/              # Contains unit and widget tests
├── pubspec.yaml       # Flutter dependencies and configurations
└── README.md          # Project documentation
```

## Setup Instructions
1. **Clone the repository**:
   ```bash
   git clone https://github.com/Yuji-ctrl/lotteryAppMobile.git
   cd lotteryAppMobile
   ```

2. **Install Flutter**: If you haven’t installed Flutter, follow the installation instructions from the [Flutter installation documentation](https://flutter.dev/docs/get-started/install).

3. **Get dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the application**:
   ```bash
   flutter run
   ```

## Features
- View current and past lottery outcomes.
- Purchase lottery tickets directly through the app.
- User-friendly interface designed with Flutter.

## References
For more information on Flutter and how to build applications with it, refer to the official [Flutter documentation](https://flutter.dev/docs).


5. **分担**:
　Yuji-ctrl...フロントエンドメンター  
  syuyaad...発案、フロントエンド制作  
  cherry-115...バックエンド、全体設計、統合

6. **今後の展望**
   AWSはイベント限定プランだったのでVercel等に切り替えてデプロイする  
   ローカル環境でのPATH問題でFlutterのデプロイができなかったのでPC初期化の上実機で動かしてみる  
   ログイン画面でのバリデーション実装・サンプルアカウントの表示  
   位置情報取得関連のバグを修正
   くじ引き時のUX（アニメーション・効果音）にこだわる
