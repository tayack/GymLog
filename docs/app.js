const STORAGE_KEY = 'gymlog-web-history';
const SETTINGS_KEY = 'gymlog-web-settings';
const BASELINES_KEY = 'gymlog-web-routine-baselines';

const defaults = {
  duration: 90,
  webhookUrl: '',
};

const ui = {
  timerDisplay: document.getElementById('timerDisplay'),
  timerStatus: document.getElementById('timerStatus'),
  startButton: document.getElementById('startTimer'),
  resetButton: document.getElementById('resetTimer'),
  durationInput: document.getElementById('durationInput'),
  routineName: document.getElementById('routineName'),
  exerciseName: document.getElementById('exerciseName'),
  weightInput: document.getElementById('weightInput'),
  repsInput: document.getElementById('repsInput'),
  setsInput: document.getElementById('setsInput'),
  notes: document.getElementById('notes'),
  webhookUrl: document.getElementById('webhookUrl'),
  saveButton: document.getElementById('saveLog'),
  historyList: document.getElementById('historyList'),
  summaryText: document.getElementById('summaryText'),
  checkItems: Array.from(document.querySelectorAll('.check-item input[type="checkbox"]')),
  form: document.getElementById('routineForm'),
};

let worker = null;
let history = [];
let routineBaselines = {};
let lastConfirmPrompt = false;
let prCelebrationPending = false;
let timerState = {
  running: false,
  remainingSeconds: defaults.duration,
};

function formatTime(totalSeconds) {
  const safeSeconds = Math.max(0, Number(totalSeconds) || 0);
  const minutes = String(Math.floor(safeSeconds / 60)).padStart(2, '0');
  const seconds = String(safeSeconds % 60).padStart(2, '0');
  return `${minutes}:${seconds}`;
}

function parseNumber(value) {
  const numberValue = Number(value);
  return Number.isFinite(numberValue) ? numberValue : null;
}

function normalizeRoutineKey(routineName, exerciseName) {
  return `${routineName.trim().toLowerCase()}::${exerciseName.trim().toLowerCase()}`;
}

function loadSettings() {
  try {
    const saved = JSON.parse(localStorage.getItem(SETTINGS_KEY) || '{}');
    ui.webhookUrl.value = saved.webhookUrl || defaults.webhookUrl;
    ui.durationInput.value = Number(saved.duration) || defaults.duration;
  } catch (error) {
    ui.durationInput.value = defaults.duration;
  }
}

function saveSettings() {
  localStorage.setItem(
    SETTINGS_KEY,
    JSON.stringify({
      duration: Number(ui.durationInput.value) || defaults.duration,
      webhookUrl: ui.webhookUrl.value.trim(),
    })
  );
}

function loadHistory() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY) || '[]');
    history = Array.isArray(saved) ? saved : [];
  } catch (error) {
    history = [];
  }
}

function saveHistory() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(history));
}

function loadRoutineBaselines() {
  try {
    const saved = JSON.parse(localStorage.getItem(BASELINES_KEY) || '{}');
    routineBaselines = saved && typeof saved === 'object' ? saved : {};
  } catch (error) {
    routineBaselines = {};
  }
}

function saveRoutineBaselines() {
  localStorage.setItem(BASELINES_KEY, JSON.stringify(routineBaselines));
}

function renderHistory() {
  if (!history.length) {
    ui.historyList.innerHTML = '<div class="history-empty">履歴はまだありません。保存するとここに表示されます。</div>';
    return;
  }

  ui.historyList.innerHTML = history
    .map((item) => {
      const date = new Date(item.savedAt).toLocaleString('ja-JP');
      const checkText = item.checks.join(' / ');
      const metricText = [
        item.weightKg !== undefined && item.weightKg !== null ? `${item.weightKg}kg` : null,
        item.reps !== undefined && item.reps !== null ? `${item.reps}回` : null,
        item.sets !== undefined && item.sets !== null ? `${item.sets}セット` : null,
      ]
        .filter(Boolean)
        .join(' / ');

      return `
        <article class="history-item">
          <p class="history-date">${item.date}</p>
          <p class="history-meta">${date} · ${item.routineName} · ${item.exerciseName}</p>
          <p class="history-meta">${metricText || '記録値未入力'}</p>
          <p class="history-meta">チェック: ${checkText}</p>
          ${item.notes ? `<p class="history-memo">${item.notes}</p>` : ''}
        </article>
      `;
    })
    .join('');
}

function setStatus(message, tone = 'neutral', highlight = false) {
  const toneMap = {
    neutral: 'rgba(255, 255, 255, 0.03)',
    success: 'rgba(110, 231, 183, 0.18)',
    warning: 'rgba(255, 209, 102, 0.18)',
  };

  ui.timerStatus.classList.remove('pr-celebration');
  ui.timerStatus.textContent = message;
  ui.timerStatus.style.background = toneMap[tone] || toneMap.neutral;

  if (highlight) {
    ui.timerStatus.classList.add('pr-celebration');
    window.clearTimeout(ui.timerStatus._celebrateTimeout);
    ui.timerStatus._celebrateTimeout = window.setTimeout(() => {
      ui.timerStatus.classList.remove('pr-celebration');
    }, 2600);
  }
}

function updateTimerDisplay(seconds) {
  timerState.remainingSeconds = Math.max(0, Number(seconds) || 0);
  ui.timerDisplay.textContent = formatTime(timerState.remainingSeconds);
}

function updateProgressSummary() {
  const completed = ui.checkItems.filter((checkbox) => checkbox.checked).length;
  const total = ui.checkItems.length;
  ui.summaryText.innerHTML = `チェック完了: <strong>${completed}/${total}</strong>  · 保存前に必ず確認を行います。`;
}

function checkFormReady() {
  return Boolean(
    ui.routineName.value.trim() &&
      ui.exerciseName.value.trim() &&
      ui.checkItems.every((checkbox) => checkbox.checked)
  );
}

function validationMessage() {
  if (!ui.routineName.value.trim()) {
    return 'ルーティン名を入力してください。';
  }

  if (!ui.exerciseName.value.trim()) {
    return '種目名を入力してください。';
  }

  const missing = ui.checkItems
    .filter((checkbox) => !checkbox.checked)
    .map((checkbox) => checkbox.dataset.label || 'チェック');

  if (missing.length) {
    return `次のチェックを完了してください: ${missing.join(', ')}`;
  }

  return '';
}

function requestNotificationPermission() {
  if (!('Notification' in window)) {
    return;
  }

  if (Notification.permission === 'default') {
    Notification.requestPermission().catch(() => {});
  }
}

function sendNotification(title, body) {
  const payload = {
    title,
    body,
    source: 'GymLog Web Timer',
    timestamp: new Date().toISOString(),
  };

  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification(title, { body, tag: 'gymlog-timer' });
  }

  const webhookUrl = ui.webhookUrl.value.trim();
  if (!webhookUrl) {
    return;
  }

  fetch(webhookUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  }).catch((error) => {
    console.warn('Webhook notification failed', error);
  });
}

function getRoutineBaseline(routineName, exerciseName) {
  const key = normalizeRoutineKey(routineName, exerciseName);
  return routineBaselines[key] || null;
}

function updateRoutineBaseline(routineName, exerciseName, currentWeight, currentSets) {
  const key = normalizeRoutineKey(routineName, exerciseName);
  const previousBaseline = routineBaselines[key] || {};

  routineBaselines[key] = {
    bestWeight: currentWeight,
    sets: currentSets || previousBaseline.sets || null,
    updatedAt: new Date().toISOString(),
  };

  saveRoutineBaselines();
}

function getRecordMetrics() {
  const weightKg = parseNumber(ui.weightInput.value);
  const reps = parseNumber(ui.repsInput.value);
  const sets = parseNumber(ui.setsInput.value);

  return {
    weightKg,
    reps,
    sets,
  };
}

function maybeHandleRoutineBaselineUpdate(routineName, exerciseName, currentWeight, currentSets) {
  if (currentWeight === null) {
    return null;
  }

  const baseline = getRoutineBaseline(routineName, exerciseName);
  if (!baseline) {
    updateRoutineBaseline(routineName, exerciseName, currentWeight, currentSets);
    return null;
  }

  if (currentWeight <= baseline.bestWeight) {
    return null;
  }

  const confirmUpdate = window.confirm(
    `🎉 最高記録更新おめでとうございます！\n\n${routineName} / ${exerciseName} の基準値を ${currentWeight}kg に更新しますか？\n\n「はい」を選ぶと、ルーティンの基準値を更新します。`
  );

  if (confirmUpdate) {
    updateRoutineBaseline(routineName, exerciseName, currentWeight, currentSets);
    prCelebrationPending = true;
    return '基準値を更新しました。記録も保存しました。';
  }

  prCelebrationPending = false;
  return '記録を保存しました。基準値はそのままです。';
}

function saveRecord({ skipConfirm = false } = {}) {
  if (!checkFormReady()) {
    window.alert(validationMessage());
    return;
  }

  if (!skipConfirm) {
    const confirmSave = window.confirm('すべてのチェックが完了しました。データを保存しますか？');
    if (!confirmSave) {
      setStatus('保存はキャンセルされました。', 'warning');
      return;
    }
  }

  const routineName = ui.routineName.value.trim();
  const exerciseName = ui.exerciseName.value.trim();
  const metrics = getRecordMetrics();

  const statusMessage = maybeHandleRoutineBaselineUpdate(
    routineName,
    exerciseName,
    metrics.weightKg,
    metrics.sets
  );

  const record = {
    date: new Date().toLocaleDateString('ja-JP'),
    savedAt: new Date().toISOString(),
    routineName,
    exerciseName,
    notes: ui.notes.value.trim(),
    checks: ui.checkItems.map((checkbox) => checkbox.dataset.label || checkbox.id),
    weightKg: metrics.weightKg,
    reps: metrics.reps,
    sets: metrics.sets,
  };

  history.unshift(record);
  history = history.slice(0, 20);
  saveHistory();
  renderHistory();
  setStatus(
    statusMessage || '保存しました。次のセットに向けて続けてください。',
    'success',
    prCelebrationPending
  );
  prCelebrationPending = false;
  ui.form.reset();
  updateProgressSummary();
  lastConfirmPrompt = false;
}

function handleAutoSavePrompt() {
  if (!checkFormReady() || lastConfirmPrompt) {
    return;
  }

  lastConfirmPrompt = true;
  saveRecord({ skipConfirm: true });
}

function startTimer() {
  const duration = Math.max(1, Number(ui.durationInput.value) || defaults.duration);
  timerState.running = true;
  updateTimerDisplay(duration);
  setStatus('タイマー実行中です。画面を閉じてもバックグラウンドでカウントダウンします。');
  worker.postMessage({ type: 'start', durationSeconds: duration });
  ui.startButton.disabled = true;
  ui.resetButton.disabled = false;
}

function resetTimer() {
  timerState.running = false;
  worker.postMessage({ type: 'stop' });
  updateTimerDisplay(Number(ui.durationInput.value) || defaults.duration);
  setStatus('タイマーをリセットしました。');
  ui.startButton.disabled = false;
}

function bindEvents() {
  ui.startButton.addEventListener('click', startTimer);
  ui.resetButton.addEventListener('click', resetTimer);
  ui.saveButton.addEventListener('click', (event) => {
    event.preventDefault();
    saveRecord();
  });

  ui.durationInput.addEventListener('change', () => {
    saveSettings();
    updateTimerDisplay(Number(ui.durationInput.value) || defaults.duration);
  });

  ui.webhookUrl.addEventListener('change', saveSettings);

  ui.form.addEventListener('input', () => {
    lastConfirmPrompt = false;
    updateProgressSummary();
    if (checkFormReady()) {
      handleAutoSavePrompt();
    }
  });

  ui.checkItems.forEach((checkbox) => {
    checkbox.addEventListener('change', () => {
      lastConfirmPrompt = false;
      updateProgressSummary();
      if (checkFormReady()) {
        handleAutoSavePrompt();
      }
    });
  });
}

function handleWorkerMessage(event) {
  const { type, remainingSeconds, title, body } = event.data || {};

  if (type === 'tick') {
    updateTimerDisplay(remainingSeconds);
    if (remainingSeconds === 30) {
      setStatus('あと30秒です。準備を始めてください。', 'warning');
    }
    return;
  }

  if (type === 'done') {
    timerState.running = false;
    ui.startButton.disabled = false;
    updateTimerDisplay(0);
    setStatus('インターバル終了です。次のセットへGO。', 'success');
    sendNotification(title, body);
    return;
  }

  if (type === 'notify') {
    setStatus('予告通知を送信しました。', 'warning');
    sendNotification(title, body);
  }
}

function init() {
  loadSettings();
  loadHistory();
  loadRoutineBaselines();
  renderHistory();
  updateTimerDisplay(Number(ui.durationInput.value) || defaults.duration);
  updateProgressSummary();
  bindEvents();
  requestNotificationPermission();

  if (typeof Worker === 'undefined') {
    setStatus('このブラウザではWeb Workerが利用できないため、タイマーを起動できません。');
    return;
  }

  worker = new Worker('timer-worker.js');
  worker.onmessage = handleWorkerMessage;
  worker.onerror = (error) => {
    console.error('Timer worker error', error);
    setStatus('タイマーのバックグラウンド処理でエラーが発生しました。');
  };
}

document.addEventListener('DOMContentLoaded', init);
