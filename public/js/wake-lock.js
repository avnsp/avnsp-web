if ('wakeLock' in navigator) {
  var wakeLock = null;

  function acquireWakeLock() {
    navigator.wakeLock.request('screen').then(function (lock) {
      wakeLock = lock;
      lock.addEventListener('release', function () { wakeLock = null; });
    }).catch(function () {});
  }

  acquireWakeLock();

  document.addEventListener('visibilitychange', function () {
    if (document.visibilityState === 'visible') acquireWakeLock();
  });
}
