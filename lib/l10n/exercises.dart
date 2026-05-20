const _exercisesJa = [
  // 胸
  'ベンチプレス', 'インクラインベンチプレス', 'デクラインベンチプレス',
  'ダンベルフライ', 'インクラインダンベルフライ', 'ケーブルフライ',
  'ケーブルクロスオーバー', 'ペックデックフライ', 'バタフライ',
  'チェストプレスマシン',
  // 肩
  'ショルダープレス', 'アーノルドプレス', 'ショルダープレスマシン',
  'サイドレイズ', 'フロントレイズ', 'リアデルトフライ',
  'ケーブルサイドレイズ', 'フェイスプル', 'アップライトロウ',
  'バーベルシュラッグ',
  // 背中
  'デッドリフト', 'ラットプルダウン', 'チンアップ', 'プルアップ',
  'アシストチンアップマシン',
  'シーテッドケーブルロウ', 'バーベルロウ', 'Tバーロウ', 'ワンアームダンベルロウ',
  'バックエクステンション', 'ダンベルプルオーバー',
  // 脚
  'スクワット', 'スミスマシンスクワット', 'ブルガリアンスクワット', 'ランジ',
  'レッグプレス', 'レッグエクステンション', 'レッグカール',
  'カーフレイズ', 'シーテッドカーフレイズ',
  'ヒップスラスト', 'グルートキックバック',
  'ルーマニアンデッドリフト', 'ゴブレットスクワット', 'ハックスクワット',
  'アダクション', 'アブダクション',
  // 上腕二頭筋
  'ダンベルカール', 'バーベルカール', 'ハンマーカール',
  'ケーブルカール', 'プリーチャーカール',
  // 上腕三頭筋
  'トライセプスプッシュダウン', 'スカルクラッシャー', 'ディップス',
  'トライセプスキックバック', 'オーバーヘッドトライセプスエクステンション',
  // 体幹
  'プランク', 'クランチ', 'シットアップ', 'レッグレイズ',
  'アブローラー', 'ロシアンツイスト', 'ケーブルクランチ',
  'アブドミナルマシン', 'ロータリートルソー',
  // 有酸素・その他
  'ランニング', 'サイクリング', 'ローイングマシン',
  'ステアクライマー', 'エリプティカル',
  'ジャンプロープ', 'バーピー', 'ケトルベルスイング',
];

const _exercisesEn = [
  // Chest
  'Bench Press', 'Incline Bench Press', 'Decline Bench Press',
  'Dumbbell Fly', 'Incline Dumbbell Fly', 'Cable Fly',
  'Cable Crossover', 'Pec Deck Fly', 'Butterfly Machine',
  'Chest Press Machine',
  // Shoulders
  'Shoulder Press', 'Arnold Press', 'Machine Shoulder Press',
  'Lateral Raise', 'Front Raise', 'Rear Delt Fly',
  'Cable Lateral Raise', 'Face Pull', 'Upright Row',
  'Barbell Shrug',
  // Back
  'Deadlift', 'Lat Pulldown', 'Chin-up', 'Pull-up',
  'Assisted Pull-up Machine',
  'Seated Cable Row', 'Barbell Row', 'T-Bar Row', 'One-Arm Dumbbell Row',
  'Back Extension', 'Dumbbell Pullover',
  // Legs
  'Squat', 'Smith Machine Squat', 'Bulgarian Split Squat', 'Lunge',
  'Leg Press', 'Leg Extension', 'Leg Curl',
  'Calf Raise', 'Seated Calf Raise',
  'Hip Thrust', 'Glute Kickback',
  'Romanian Deadlift', 'Goblet Squat', 'Hack Squat',
  'Hip Adduction Machine', 'Hip Abduction Machine',
  // Biceps
  'Dumbbell Curl', 'Barbell Curl', 'Hammer Curl',
  'Cable Curl', 'Preacher Curl',
  // Triceps
  'Triceps Pushdown', 'Skull Crusher', 'Dips',
  'Triceps Kickback', 'Overhead Triceps Extension',
  // Core
  'Plank', 'Crunch', 'Sit-up', 'Leg Raise',
  'Ab Roller', 'Russian Twist', 'Cable Crunch',
  'Ab Machine', 'Rotary Torso',
  // Cardio & Other
  'Running', 'Cycling', 'Rowing Machine',
  'Stair Climber', 'Elliptical',
  'Jump Rope', 'Burpee', 'Kettlebell Swing',
];

List<String> getExercises(String languageCode) =>
    languageCode == 'ja' ? _exercisesJa : _exercisesEn;

/// ひらがな→カタカナ変換＋小文字化。
/// 「あ」→「ア」に変換して検索するため、ひらがなでカタカナ種目をヒットさせる。
String normalizeForSearch(String s) => s
    .replaceAllMapped(
      RegExp(r'[ぁ-ゖ]'),
      (m) => String.fromCharCode(m[0]!.codeUnitAt(0) + 0x60),
    )
    .toLowerCase();
