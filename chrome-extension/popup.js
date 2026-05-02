import Tesseract from './libs/tesseract.min.js';

document.getElementById('syncNow').addEventListener('click', () => {
  chrome.runtime.sendMessage({ action: 'manualSync' });
});

chrome.runtime.onMessage.addListener((message) => {
  if (message.status) {
    document.getElementById('status').innerText = message.status;

    if (message.status === 'Sync done') {
      document.getElementById('status').style.color = 'green';

      // close the popup after 4 seconds
      setTimeout(() => {
        window.close();
      }, 4000);
    }
  }
});

document.getElementById("capture").addEventListener("click", async () => {
  const [tab] = await chrome.tabs.query({ active: true, currentWindow: true });
  console.log({tab});

  chrome.tabs.captureVisibleTab(tab.windowId, { format: "png" }, async (dataUrl) => {
    const img = new Image();
    img.src = dataUrl;

    img.onload = async () => {
      console.log({img});
      const canvas = document.createElement("canvas");
      const context = canvas.getContext("2d");
      canvas.width = img.width;
      canvas.height = img.height;
      context.drawImage(img, 0, 0);
      const extractedText = await runOCR(canvas);
      document.getElementById("output").textContent = extractedText;
    };
  });
});

// Run Tesseract.js OCR
async function runOCR(image) {
  const { createWorker } = Tesseract;
  const worker = createWorker();
  await worker.load();
  await worker.loadLanguage("eng");
  await worker.initialize("eng");
  const { data: { text } } = await worker.recognize(image);
  await worker.terminate();
  console.log(text);
  return text;
}