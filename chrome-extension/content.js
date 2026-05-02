// Placeholder content script (not required to do much since `scrapeHighlights` is executed via `background.js`).
const start = () => {
  if (document.URL.match(/amazon/) && document.URL.match(/\/notebook/) && document.URL.match(/(\?|&)ntsync/)) {
    console.log("Amazon page detected from Notebase");
    chrome.runtime.sendMessage({ action: 'manualSync' });
  }
}

start();