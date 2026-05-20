class AppStrings {
  const AppStrings(this.languageCode);
  final String languageCode;
  bool get _ja => languageCode == 'ja';

  // Tabs
  String get tabToday    => _ja ? '記録'       : 'Log';
  String get tabTimer    => _ja ? 'タイマー'   : 'Timer';
  String get tabHistory  => _ja ? '履歴'        : 'History';
  String get tabRoutines => _ja ? 'ルーティン' : 'Routines';
  String get tabSettings => _ja ? '設定'        : 'Settings';

  // Login
  String get loginGoogle    => _ja ? 'Googleでログイン'                        : 'Sign in with Google';
  String get loginGuest     => _ja ? 'ゲストとして使う'                        : 'Continue as Guest';
  String get loginGuestNote => _ja ? 'ゲストのデータはこの端末のみで保持されます' : 'Guest data is stored on this device only';

  // Workout
  String get selectRoutine  => _ja ? 'ルーティンを選択' : 'Select a Routine';
  String get noRoutines     => _ja ? 'ルーティンがまだありません' : 'No routines yet';
  String get noRoutinesHint => _ja
      ? 'ルーティンタブで種目・セット数・重量をテンプレートとして保存すると、次回のワークアウトで前回の重量が自動入力されます。'
      : 'Save exercises, sets, and weights as a routine template.\nYour last weights will be auto-filled next time.';
  String get goToRoutines   => _ja ? 'ルーティンを作成する →' : 'Create a Routine →';
  String get startAdhoc     => _ja ? '+ ルーティンなしで開始' : '+ Start without routine';
  String get share          => _ja ? '共有'      : 'Share';
  String get save           => _ja ? '保存'      : 'Save';
  String get saving         => _ja ? '保存中...' : 'Saving...';
  String get addExercisePlaceholder => _ja ? '種目を追加...' : 'Add exercise...';
  String get addSet         => _ja ? '+ セット追加' : '+ Add set';
  String get prevLabel      => _ja ? '前回'      : 'Last';
  String get workoutSaved        => _ja ? 'ワークアウト保存しました 💪' : 'Workout saved 💪';
  String get workoutCompleteTitle => _ja ? 'お疲れ様でした！💪' : 'Great work! 💪';
  String get workoutCompleteBody  => _ja ? 'トレーニングを完了して保存しますか？' : 'Save and finish your workout?';
  String get sharePrompt          => _ja ? 'シェアしますか？' : 'Share your workout?';
  String get cancelWorkoutTitle  => _ja ? 'ワークアウトを終了' : 'End Workout';
  String get cancelWorkoutBody   => _ja ? '記録は保存されません。終了しますか？' : 'Progress will not be saved. End workout?';
  String get discard             => _ja ? '終了する' : 'End';

  // Timer
  String get intervalTimer       => 'INTERVAL TIMER';
  String get intervalDefault     => _ja ? 'インターバルタイマー デフォルト' : 'Interval Timer Default';
  String get intervalDefaultHint => _ja
      ? 'ルーティン画面でデフォルト秒数を変更できます'
      : 'Change default duration in Routines';
  String get ready          => 'READY';
  String get resting        => 'RESTING...';
  String get complete       => 'COMPLETE!';
  String get timerNote      => _ja ? '終了時にバイブ＋通知でお知らせします' : 'Vibration + notification when done';

  // History
  String get history               => 'HISTORY';
  String get noHistory             => _ja ? 'ワークアウト履歴がありません' : 'No workout history yet';
  String get exerciseCol           => _ja ? '種目' : 'Exercise';
  String get editWorkout           => _ja ? 'ワークアウトを編集' : 'Edit Workout';
  String get deleteWorkout         => _ja ? 'ワークアウトを削除' : 'Delete Workout';
  String get deleteWorkoutConfirm  => _ja ? 'このワークアウトを削除しますか？' : 'Delete this workout?';
  String get workoutUpdated        => _ja ? 'ワークアウトを更新しました' : 'Workout updated';

  // Routines
  String get routinesDesc   => _ja
      ? 'よく行うトレーニングのテンプレートです。ワークアウト開始時にルーティンを選ぶと前回の重量が自動でセットされます。'
      : 'Templates for your typical training. Select one when starting a workout to auto-fill your last weights.';
  String get newRoutine     => _ja ? '+ 新規'          : '+ New';
  String get newRoutineLabel  => _ja ? '新規ルーティン' : 'New Routine';
  String get editRoutineLabel => _ja ? 'ルーティンを編集' : 'Edit Routine';
  String get routineNameHint  => _ja ? 'ルーティン名...' : 'Routine name...';
  String get addExerciseBtn => _ja ? '+ 種目を追加' : '+ Add exercise';
  String get exerciseNameHint => _ja ? '種目名' : 'Exercise name';
  String get setsLabel      => _ja ? 'セット' : 'Sets';
  String get weightLabel    => _ja ? '重量'   : 'Weight';
  String get repsLabel      => _ja ? '回数'   : 'Reps';
  String get cancel         => _ja ? 'キャンセル' : 'Cancel';
  String get delete         => _ja ? '削除'   : 'Delete';
  String get deleteConfirm  => _ja ? '削除確認'  : 'Confirm Delete';
  String deleteMsg(String name) => _ja ? '「$name」を削除しますか？' : 'Delete "$name"?';
  String get routineSaved        => _ja ? 'ルーティンを保存しました' : 'Routine saved';
  String get routineNameRequired => _ja ? 'ルーティン名を入力してください' : 'Please enter a routine name';
  String get edit                => _ja ? '編集' : 'Edit';
  String get noRoutinesDesc => _ja ? 'まだルーティンがありません' : 'No routines yet';

  // Account
  String get linkGoogle       => _ja ? 'Googleアカウントと連携'      : 'Link Google Account';
  String get linkGoogleSub    => _ja ? 'データを引き継いでアカウント登録' : 'Keep data and create account';
  String get logout           => _ja ? 'ログアウト'                  : 'Sign Out';
  String get logoutGuestSub   => _ja ? 'ゲストデータにアクセスできなくなります' : 'Guest data will become inaccessible';
  String get logoutGuestBody  => _ja
      ? 'ログアウトするとゲストデータにアクセスできなくなります。\nデータを残したい場合はGoogleアカウントと連携してください。'
      : 'Logging out will make your guest data inaccessible.\nLink a Google account to keep your data.';
  String get deleteAccount    => _ja ? 'アカウントとデータを削除'    : 'Delete Account & Data';
  String get deleteAccountSub => _ja ? 'すべてのデータが完全に削除されます' : 'All data will be permanently deleted';
  String get deleteAccountTitle => _ja ? 'アカウントを削除'          : 'Delete Account';
  String get deleteAccountBody  => _ja
      ? 'すべてのワークアウト記録・ルーティンが完全に削除されます。\nこの操作は取り消せません。'
      : 'All workout records and routines will be permanently deleted.\nThis cannot be undone.';
  String get language         => _ja ? '言語設定'   : 'Language';
  String get japanese         => '日本語';
  String get english          => 'English';
  String get guestBadge       => 'GUEST';
  String get account          => _ja ? 'アカウント' : 'Account';
  String get linkedGoogle     => _ja ? 'Googleアカウントと連携しました' : 'Linked to Google Account';
  String get deleteFailed     => _ja
      ? '削除失敗。再ログインして再試行してください'
      : 'Delete failed. Please re-login and try again.';

  // Wheel picker
  String get selectWeight => _ja ? '重量を選択' : 'Select Weight';
  String get selectReps   => _ja ? '回数を選択' : 'Select Reps';
  String get selectSets   => _ja ? 'セット数を選択' : 'Select Sets';
  String get done         => _ja ? '決定' : 'Done';

  // Timer notifications
  String get notifTimerBody   => _ja ? 'インターバル終了！次のセットへ' : 'Interval done! Next set.';
  String get notifChannelName => _ja ? 'タイマー通知' : 'Timer Alerts';
  String get notifChannelDesc => _ja ? 'インターバルタイマー終了通知' : 'Interval timer completion';
}
