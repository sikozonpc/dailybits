import Tesseract from './libs/tesseract.min.js';

chrome.runtime.onMessage.addListener(async (info) => {
  if (info.action === "parse-yt-video") {
    const currentVideo = document.querySelector("video");
    if (currentVideo) {
      const currentTime = Math.floor(currentVideo.currentTime);

      const url = new URL(window.location.href);
      url.searchParams.set("t", currentTime.toString());

      const videoText = document.querySelector(".style-scope .ytd-watch-metadata").innerText;
      const title = videoText.split("\n")[0];
      const author = videoText.split("\n")[1];

      const chapterName = document.querySelector(".ytp-chapter-title-content").innerText;

      const videoURL = url.toString();

      const metadata = {
        author,
        chapterName,
      };

      // Create a canvas element
      const canvas = document.createElement('canvas');
      canvas.width = currentVideo.videoWidth;
      canvas.height = currentVideo.videoHeight;
      const context = canvas.getContext('2d');

      // Draw the current video frame onto the canvas
      context.drawImage(currentVideo, 0, 0, canvas.width, canvas.height);

      // Get the image data URL from the canvas
      const imageDataURL = canvas.toDataURL('image/png');
      const extractedText = await runOCR(imageDataURL);
      console.log({ extractedText });

      chrome.runtime.sendMessage({
        action: 'save-yt-video',
        data: {
          mediaType: 'video',
          videoURL,
          title,
          metadata,
          imageDataURL, // Add the image data URL to the message
        },
      });
    } else {
      console.error("No active video found!");
    }
  }
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