import { saveObject } from './object.js';

// Define the context menu item
chrome.runtime.onInstalled.addListener(() => {
  chrome.contextMenus.create({
    id: "save-selection",
    title: "Save to Notebase",
    contexts: ["selection", "image", "audio", "link"],
  });
  chrome.contextMenus.create({
    id: "clip-yt-video",
    title: "Save to Notebase",
    contexts: ["video"],
    documentUrlPatterns: ["https://*.youtube.com/*"]
  });
});

chrome.contextMenus.onClicked.addListener((info, tab) => {
  if (info.menuItemId === "clip-yt-video") {
    chrome.tabs.sendMessage(tab.id, { action: "parse-yt-video" });
  }
});

chrome.contextMenus.onClicked.addListener(async (info, tab) => {
  if (info.menuItemId === "save-selection") {
    await saveObject(info, tab);
  }
});

chrome.runtime.onMessage.addListener(async (info, tab) => {
  if (info.action === "save-yt-video") {
    await saveObject(info.data, tab.tab);
  }
});
