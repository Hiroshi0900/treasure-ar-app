# Flutter AR宝探しアプリ開発プロジェクト

## プロジェクト概要
0〜1歳の乳幼児とその保護者が一緒に楽しめるAR（拡張現実）を活用した宝探しゲームアプリの開発。

## 技術スタック
- Flutter (iOS向け)
- ARKit (arkit_plugin使用)
- Dart言語

## 開発環境
- macOS
- Xcode
- Flutter SDK
- CocoaPods
- fishシェル（デフォルトシェル）

## geminiコマンドについて
Web検索やAI支援が必要な際は`gemini`コマンドを使用する。

### 使用方法
```bash
# 基本的な使い方
echo "質問内容" | gemini -p "詳しく説明してください"

# モデル指定（デフォルト: gemini-2.5-pro）
echo "質問内容" | gemini -m "gemini-2.5-pro" -p "要約してください"

# デバッグモード
echo "質問内容" | gemini -d -p "説明してください"
```

### geminiオプション
- `-m, --model`: 使用するモデル（デフォルト: "gemini-2.5-pro"）
- `-p, --prompt`: プロンプト（標準入力に追加される）
- `-s, --sandbox`: サンドボックスモードで実行
- `-d, --debug`: デバッグモード
- `-a, --all_files`: すべてのファイルをコンテキストに含める
- `-y, --yolo`: すべてのアクションを自動的に承認（YOLOモード）

## コマンド集
```bash
# Flutter環境確認
flutter doctor

# 依存関係インストール
flutter pub get

# iOSシミュレーター起動
open -a Simulator

# アプリ実行
flutter run

# ビルド（リリース）
flutter build ios --release
```

## fishシェル設定
```fish
# PATHが通らない場合は~/.config/fish/config.fishに追加
set -gx PATH $PATH /opt/homebrew/bin/flutter/bin

# 設定反映
source ~/.config/fish/config.fish
```

## 開発ルール・方針

### 1. TDD（テスト駆動開発）
- **必須**: すべての機能実装前にテストを先に書く
- **テストの種類**:
  - **Unit Test**: ビジネスロジック、ドメインモデル、値オブジェクト
  - **Widget Test**: UI コンポーネントの振る舞い、状態管理
  - **Integration Test**: BEのITテスト相当
    - 実デバイス/シミュレーターで実行
    - AR機能との統合（カメラ、平面検出）
    - 画面遷移のE2Eテスト
    - パフォーマンステスト（描画速度、メモリ使用量）
    - ユーザーシナリオテスト（宝箱配置→探索→発見の一連の流れ）

### 2. DDD（ドメイン駆動設計）
- **層構造**:
  - Presentation層: UI/ウィジェット
  - Application層: ユースケース
  - Domain層: エンティティ、値オブジェクト、リポジトリインターフェース
  - Infrastructure層: AR実装、永続化実装

### 3. 型安全性
- **状態の型表現**: Sealed classやUnion型で状態を表現
```dart
// 悪い例
class TreasureBox {
  final String status; // "hidden", "found", "opened"
}

// 良い例
sealed class TreasureBoxState {}
class HiddenTreasureBox extends TreasureBoxState {
  final Vector3 position;
}
class FoundTreasureBox extends TreasureBoxState {
  final Vector3 position;
  final DateTime foundAt;
}
class OpenedTreasureBox extends TreasureBoxState {
  final Vector3 position;
  final DateTime foundAt;
  final DateTime openedAt;
}
```

### 4. Makefile構成
```makefile
# テスト関連
test:
	flutter test

test-unit:
	flutter test test/unit

test-widget:
	flutter test test/widget

test-integration:
	flutter test integration_test

test-coverage:
	flutter test --coverage
	genhtml coverage/lcov.info -o coverage/html
	open coverage/html/index.html

# 静的解析・フォーマット
lint:
	flutter analyze
	dart format --set-exit-if-changed .

format:
	dart format .

fix:
	dart fix --apply

# ビルド関連
build-ios:
	flutter build ios --release

build-debug:
	flutter build ios --debug

# 総合チェック
check: lint test build-debug

check-full: lint test test-integration build-ios test-coverage

# 依存関係管理
pub-get:
	flutter pub get

pub-upgrade:
	flutter pub upgrade

pub-outdated:
	flutter pub outdated

# 環境セットアップ
setup: pub-get
	cd ios && pod install

# クリーンアップ
clean:
	flutter clean
	cd ios && rm -rf Pods && rm Podfile.lock

reset: clean setup

# TDDワークフロー
tdd-cycle: test-unit format check
```

### 5. 検査項目
- **flutter analyze**: 静的解析（型チェック、未使用変数等）
- **dart format**: コードフォーマット
- **flutter test**: 全テスト実行
- **flutter build ios**: iOS向けビルド可能性確認
- **coverage**: テストカバレッジ（目標: 80%以上）
  ```bash
  flutter test --coverage
  genhtml coverage/lcov.info -o coverage/html
  ```
- **dart fix**: 自動修正可能な問題の検出
- **flutter pub outdated**: 依存関係の更新確認
- **golden test**: UI回帰テスト（スクリーンショット比較）
- **performance test**: AR描画のFPS測定
- **メモリリーク検査**: Flutter DevToolsでのプロファイリング
- **アクセシビリティ検査**: Semantics widgetの適切な使用

### 6. TDDワークフロー
```bash
# 1. RED: テスト作成（失敗するテスト）
# 例：宝箱配置機能のテスト
vim test/unit/domain/treasure_box_test.dart

# 2. GREEN: 最小限の実装でテストを通す
vim lib/domain/entities/treasure_box.dart

# 3. テスト実行（単体テスト）
make test-unit

# 4. REFACTOR: リファクタリング
make tdd-cycle  # テスト + フォーマット + チェック

# 5. 統合テスト（必要に応じて）
make test-integration

# 6. 最終チェック
make check

# 7. コミット
git add .
git commit -m "feat: add treasure box placement domain logic"
```

### 7. コミット規則
- **粒度**: 1機能1コミット（TDDサイクル完了後）
- **メッセージ**: Conventional Commits準拠
  - `feat:` 新機能
  - `fix:` バグ修正
  - `test:` テスト追加・修正
  - `refactor:` リファクタリング
  - `docs:` ドキュメント更新
  - `style:` フォーマット修正
  - `perf:` パフォーマンス改善

### 8. プロジェクト構造
```
lib/
├── main.dart
├── presentation/
│   ├── pages/
│   ├── widgets/
│   └── providers/
├── application/
│   └── use_cases/
├── domain/
│   ├── entities/
│   ├── value_objects/
│   └── repositories/
└── infrastructure/
    ├── ar/
    └── repositories/

test/
├── unit/
├── widget/
└── fixtures/

integration_test/
```

## アプリの主要機能
1. AR平面検出（床・壁）
2. 宝箱の3D配置
3. モード切り替え（大人/子供）
4. 宝箱探索とヒント表示
5. 発見時の演出（アニメーション・音声）

## 0-1歳児向け設計配慮
- 大きなタップ領域
- シンプルで鮮やかな視覚効果
- 心地よい音響効果
- 親モードの誤操作防止（長押し切り替え）
- 短時間（数分）で完結するゲーム設計