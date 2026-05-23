let timerId = null;
let endTime = 0;
let currentDuration = 0;

function clearTimer() {
  if (timerId !== null) {
    clearInterval(timerId);
    timerId = null;
  }
}

function sendProgress(remainingSeconds) {
  self.postMessage({
    type: 'tick',
    remainingSeconds,
    totalSeconds: currentDuration,
  });

  if (remainingSeconds === 30) {
    self.postMessage({
      type: 'notify',
      title: '🏋️ あと30秒で次のセットです！準備を始めてください。',
      body: '30秒前の予告です。次のセットに向けて準備を整えましょう。',
    });
  }

  if (remainingSeconds <= 0) {
    self.postMessage({
      type: 'done',
      title: '⏱️ インターバル終了！次のセットへGO！',
      body: 'インターバルが終了しました。次のセットを開始してください。',
    });
  }
}

self.onmessage = (event) => {
  const { type, durationSeconds } = event.data || {};

  if (type === 'start') {
    clearTimer();
    currentDuration = Number(durationSeconds) || 0;
    endTime = Date.now() + currentDuration * 1000;

    sendProgress(currentDuration);

    timerId = setInterval(() => {
      const remainingMs = endTime - Date.now();
      const remainingSeconds = Math.max(0, Math.ceil(remainingMs / 1000));

      if (remainingSeconds <= 0) {
        clearTimer();
        sendProgress(0);
        return;
      }

      sendProgress(remainingSeconds);
    }, 1000);

    return;
  }

  if (type === 'stop') {
    clearTimer();
    currentDuration = 0;
    self.postMessage({ type: 'stopped' });
  }
};
