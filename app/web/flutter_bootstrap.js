{{flutter_js}}
{{flutter_build_config}}

// Flutter's own service worker is deprecated and only unregisters itself, which
// would also remove sw.js, so the app loads without it.
_flutter.loader.load();

if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('sw.js').catch(function (e) {
    console.warn('Offline support is unavailable:', e);
  });
  // Once the app is up, tell sw.js what this load fetched, so a first visit
  // is enough for the next one to work offline.
  window.addEventListener('flutter-first-frame', function () {
    setTimeout(function () {
      navigator.serviceWorker.ready.then(function (reg) {
        var urls = performance.getEntriesByType('resource').map(function (e) {
          return e.name;
        });
        urls.push(document.baseURI);
        if (reg.active) reg.active.postMessage({ type: 'remember', urls: urls });
      });
    }, 4000);
  });
}
