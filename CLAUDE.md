# GymLog — CLAUDE.md

## プロジェクト概要

筋トレ記録アプリ。Flutter (Android 主体) + Firebase バックエンド。
Google Sign-In / 匿名ゲストモードに対応。インターバルタイマー・PR 自動更新・ルーティン管理が主機能。

- **パッケージ名**: `com.gymlog.app`
- **アプリ名**: GymLog - Workout Tracker
- **バージョン**: 1.0.0+1 (`pubspec.yaml`)
- **Flutter SDK**: ^3.10.7 / Dart SDK ^3.10.7

---

## ディレクトリ構成

```
lib/
  main.dart              # エントリポイント・AuthGate・LoginScreen・HomeScreen
  firebase_options.dart  # FlutterFire 生成ファイル（編集不要）
  models/
    workout_model.dart   # WorkoutModel, SetEntry
    menu_model.dart      # MenuModel（ルーティン）
  screens/
    workout_screen.dart  # 記録入力（メインタブ）
    history_screen.dart  # 履歴テーブル
    menu_screen.dart     # ルーティン管理
    settings_screen.dart # 設定（言語・アカウント削除）
    timer_screen.dart    # インターバルタイマー
  services/
    auth_service.dart    # Google Sign-In / 匿名ログイン / サインアウト
    firestore_service.dart # Firestore CRUD
  providers/
    locale_provider.dart # 言語切替（ja/en）
  widgets/
    banner_ad_widget.dart # AdMob バナー
    wheel_picker.dart    # ピッカーウィジェット
  l10n/
    strings.dart         # 日英ローカライズ文字列
    exercises.dart       # 種目名リスト
  theme/
    app_theme.dart       # テーマ定義（ダーク, アクセント: #E63946）

docs/                    # GitHub Pages ランディングページ
  index.html             # LP + プライバシーポリシー + お問い合わせ
  styles.css             # LP + ダッシュボード CSS（root font-size: 19px）
  app.js                 # Web タイマー・履歴ログ・保存確認ダイアログ
  timer-worker.js        # Web Worker（30秒前通知 + 終了通知）
```

---

## 実装済みの主要フロー

### 保存時PR演出フロー（workout_screen.dart）
```
全セット完了 → 保存確認ダイアログ → saveWorkout()（新PR Map返却）
  → PR達成あり？
      Yes（ルーティン選択中）→「🎉 最高記録達成！＋ルーティン更新しますか？」一括ダイアログ
                             → Yes: saveMenu()でルーティン重量更新
      Yes（アドホック）      →「🎉 最高記録達成！」のみ
  → シェアしますか？ダイアログ → 履歴タブへ
```
- `_showPrAndRoutineDialog(newPRs, menu)` で実装
- ルーティン更新は「既存PRを上回った種目のみ」weight/reps を上書き

### 削除時PR再計算（history_screen.dart / firestore_service.dart）
- `deleteWorkout` 後に `recalcPRsForExercises(exerciseNames)` を呼ぶ
- 全ワークアウトをスキャンして種目別に最高値を再計算
- 記録が0件になった種目はPRドキュメントを削除

### インターバルタイマー通知（workout_screen.dart）
- チャンネルID: `timer_channel_v2`（v1から変更済み、チャンネル不変性のため）
- バイブレーション: `hasVibrator()` チェック → `await Vibration.vibrate(pattern:[...])`
- `vibrationPattern` + `category: alarm` + `visibility: public` でスマートウォッチへの橋渡しを最適化
- スマートウォッチ側の振動はウォッチ本体の設定に依存する部分がある

---

## Firestore データ構造

```
users/{uid}/
  menus/      # ルーティン（MenuModel）
  workouts/   # ワークアウト記録（WorkoutModel）, date 降順
  prs/        # 種目ごとの最高記録（SetEntry）
```

---

## 主要パッケージ

| カテゴリ | パッケージ |
|---|---|
| Firebase | firebase_core, firebase_auth, cloud_firestore, google_sign_in |
| 通知・振動 | flutter_local_notifications, vibration |
| 広告 | google_mobile_ads (AdMob) |
| 状態管理 | provider |
| 永続化 | shared_preferences |
| ローカライズ | intl, flutter_localizations |
| UI | flutter_native_splash, share_plus |

---

## よく使うコマンド

```bash
# 実行
flutter run

# 静的解析
flutter analyze

# テスト
flutter test

# Android APK ビルド
flutter build apk --release

# アイコン生成（assets/icon/app_icon.png 変更後）
dart run flutter_launcher_icons

# スプラッシュ生成
dart run flutter_native_splash:create
```

---

## 認証フロー

```
AuthGate (StreamBuilder on authState)
  ├─ null → LoginScreen（Google Sign-In / ゲストモード）
  └─ User → HomeScreen（BottomNavigationBar 4タブ）
             記録 / 履歴 / ルーティン / 設定
```

---

## Web ランディングページ仕様

- `docs/` を GitHub Pages で公開
- **タイマー**: Web Worker ベース（スリープ中も継続）
  - 残り 30 秒 → `notify` イベント → Notification API + Webhook
  - 終了 → `done` イベント → Notification API + Webhook
- **広告枠**: `.ad-banner` が `position: fixed; bottom: 0` で常時表示
- **フォントサイズ**: `:root { font-size: 19px }` (ベース 15px 比 約 1.27 倍)
- **履歴日付**: `font-size: 1.5rem`, `font-weight: 800`, Space Mono, 左ボーダー赤

---

## テーマ・デザイン規約

- **背景**: `#0D0D0F`（ほぼ黒）
- **アクセント**: `#E63946`（赤）
- **フォント (Flutter)**: システムデフォルト。`app_theme.dart` に定義
- **フォント (Web)**: Space Mono（見出し・数字）/ Noto Sans JP（本文）
- コメントは「WHY が自明でない場合のみ」記述

---

## 注意事項

- `firebase_options.dart` は FlutterFire CLI 生成ファイル。直接編集しない。
- AdMob App ID は `AndroidManifest.xml` の `com.google.android.gms.ads.APPLICATION_ID` に記載。
- `docs/` の変更は GitHub Pages に直接反映される（main ブランチ push 後）。
- iOS ビルドは構造のみ存在。現在 Android のみ対象。
