import { parseHTML } from './libs/linkedom.min.js';
import { sendDataToServer } from './utils.js';
import './web-clipper.js'

let at = ""

const isDev = true

const MAX_RETRIES = 3;

const INITIAL_SYNC_PROCESS = {
  books: {},
  status: "idle",
  userName: "",
}
const LANDING_PAGE_URL = isDev ? "http://localhost:4000" : "https://get.notebase.org/welcome";

let syncProcess = INITIAL_SYNC_PROCESS;
let cookieString = ''

chrome.runtime.onInstalled.addListener((details) => {
  console.log("Extension Installed", details);

  if (details?.reason === "install") {
    // Open the landing page on the first install
    chrome.tabs.create({ url: LANDING_PAGE_URL });
  }

  // TODO: Only sync if authenticated - Create an alarm to run every 24 hours
  const firsSyncTime = 1000
  const oneDayInMins = 24 * 60
  chrome.alarms.create("daily-sync", { periodInMinutes: oneDayInMins, when: Date.now() + firsSyncTime });
});

// TODO: Clear alarm and create setupAlarms function
chrome.alarms.onAlarm.addListener((alarm) => {
  if (alarm.name === "daily-sync") {
    syncAmazonHighlights();
  }
});

async function sendToServer(username) {
  // clean elements before sending to server
  Object.keys(syncProcess.books).forEach((bookId) => {
    delete syncProcess.books[bookId].el;
  });

  await sendDataToServer("/capture/sync", { username, books: syncProcess.books }, at);


  log("Syncing Amazon Highlights done");
  syncProcess = INITIAL_SYNC_PROCESS

  chrome.runtime.sendMessage({ action: 'updateStatus', status: 'Sync done' });
}

async function syncAmazonHighlights() {
  try {
    // TODO: restore auth
    // const notebaseCookies = await getNotebaseCookies()
    // if (!notebaseCookies) {
    //   console.log("Failed to get Notebase cookies, aborting sync");
    //   return
    // }
    // at = notebaseCookies;
    at = ""; // no auth for testing

    const cookies = await getAmazonCookies();
    cookieString = cookies.map(cookie => `${cookie.name}=${cookie.value}`).join('; ');

    const text = await retryFetch("")
    const document = createElement(text);

    const username = document.querySelector(".kp-notebook-username")?.innerText ?? "unknown";
    syncProcess.userName = username;

    log("Syncing Amazon Highlights");
    chrome.runtime.sendMessage({ action: 'updateStatus', status: 'Syncing...' });

    const bookIds = document.querySelectorAll('.kp-notebook-library-each-book').map((b) => b.id);
    const bookTitles = document.querySelectorAll('.kp-notebook-library-each-book-title').map((b) => b.innerText);
    // TODO: Filter out books that was seen in the previous syncs to speed this all up
    // TODO Pull remaining books paginated

    syncProcess.status = "syncing";

    bookIds.forEach(bookId => {
      syncProcess.books[bookId] = {
        id: bookId,
        highlights: [],
        el: null,
        title: "",
        lastAccessed: "",
      };
    });

    document.querySelectorAll("[id^=kp-notebook-annotated-date-]").forEach(function (dateEl) {
      const bookId = dateEl.id.replace("kp-notebook-annotated-date-", "");
      syncProcess.books[bookId].lastAccessed = new Date(dateEl.value).toISOString();
    });

    const fetchBookPromises = bookIds.map(async (bookId) => {
      syncProcess.books[bookId] = {
        id: bookId,
        highlights: [],
        el: null,
        title: bookTitles[bookIds.indexOf(bookId)],
        lastAccessed: syncProcess.books[bookId].lastAccessed,
      };

      await fetchSingleBookPages(bookId, null, null);

      // add last accessed to each highlight
      syncProcess.books[bookId].highlights.forEach(highlight => {
        highlight.lastAccessed = syncProcess.books[bookId].lastAccessed;
      });
    });

    const promises = await Promise.allSettled(fetchBookPromises);
    const rejected = promises.filter(p => p.status === 'rejected');
    if (rejected.length > 0) {
      console.error("Some books failed to sync", rejected);

      syncProcess.status = "failed";
      console.log(syncProcess)

      await sendToServer(username);
      return;
    }

    // done syncing
    syncProcess.status = "done";
    console.log(syncProcess)

    await sendToServer(username);
  } catch (error) {
    console.error("Error during syncAmazonHighlights:", error);
  }
}

async function fetchSingleBookPages(bookId, pageToken, contentLimitState) {
  let url = `?asin=${bookId}`

  console.log("Fetching book pages for bookId: ", bookId);
  console.log({ pageToken, contentLimitState });

  const isFirstRequest = !pageToken && !contentLimitState;
  if (!isFirstRequest) {
    url += `&token=${pageToken}&contentLimitState=${contentLimitState}&`;
  } else {
    url += `&contentLimitState=&`;
  }

  console.log({ url })

  const text = await retryFetch(url);
  const document = createElement(text);

  const nextPageToken = document.querySelector('.kp-notebook-annotations-next-page-start')?.value;
  const nextContentLimitState = document.querySelector('.kp-notebook-content-limit-state')?.value;

  if (isFirstRequest) {
    syncProcess.books[bookId].el = document;
  } else {
    console.log("...processing next page for bookId: ", bookId);
    // TODO: Need to investigate this, does the book view have pagination?
    syncProcess.books[bookId].el.querySelector('#kp-notebook-annotations').innerHTML += document.toString()
  }

  if (nextPageToken) {
    return fetchSingleBookPages(bookId, nextPageToken, nextContentLimitState);
  } else {
    return finishBookPagesParsing(bookId);
  }
}

const finishBookPagesParsing = async (bookId) => {
  console.log("FINISHING BOOK PARSING FOR BOOK: ", bookId);

  const el = syncProcess.books[bookId].el;
  const bookEl = el.querySelector("#annotation-scroller");

  const highlightElements = el.querySelector('#kp-notebook-annotations').children;

  highlightElements.forEach(function (highlightEl, i) {
    const highlightTextEl = highlightEl.querySelector("#highlight");
    const locationEl = highlightEl.querySelector("#kp-annotation-location");
    if (!locationEl || !highlightTextEl) {
      return; // skip the current element if it's not a highlight
    }


    const highlightHeaderText = highlightEl.querySelector('#annotationHighlightHeader')?.innerText;
    const highlightColor = highlightHeaderText && highlightHeaderText.split(" ")[0].trim().toLowerCase();
    var highlightNote = highlightEl.querySelector("#note")?.innerText || null;
    if (highlightNote) {
      // Fix highlightNote in weird edgecase
      highlightEl.querySelector("#note").innerHTML = highlightEl.querySelector("#note").innerHTML.replace(/<br>/mgi, "\n");
      highlightNote = highlightEl.querySelector("#note").innerText || null;
    }
    const highlightID = highlightEl.id;

    syncProcess.books[bookId].highlights.push({
      id: highlightID,
      text: highlightTextEl.innerText,
      location: locationEl.innerText,
      color: highlightColor,
      note: highlightNote,
    });

    syncProcess.books[bookId].author = bookEl.querySelector("p.kp-notebook-metadata.a-spacing-none").textContent.trim(),
      syncProcess.books[bookId].cover = bookEl.querySelector("img.kp-notebook-cover-image-border") && bookEl.querySelector("img.kp-notebook-cover-image-border").src,
      syncProcess.books[bookId].title = bookEl.querySelector("h3.kp-notebook-metadata").textContent.trim()
  });
}

function getAmazonCookies() {
  return new Promise((resolve, reject) => {
    chrome.cookies.getAll({ domain: ".amazon.com" }, (cookies) => {
      if (chrome.runtime.lastError) {
        reject(chrome.runtime.lastError);
      } else {
        resolve(cookies);
      }
    });
  });
}

function getNotebaseCookies() {
  return new Promise((resolve, reject) => {
    chrome.cookies.get({ url: LANDING_PAGE_URL, name: 'sAccessToken' },
      function (cookie) {
        if (cookie) {
          console.log("Got AT cookie successfully!");
          resolve(cookie.value)
        }
        else {
          console.log('Failed to get AT cookie');
          reject('Failed to get AT cookie')
        }
      });
  });
}

chrome.runtime.onMessage.addListener(async (request, sender, sendResponse) => {
  if (request.action === 'manualSync') {
    console.log("Manual sync triggered.");

    sendResponse({ status: 'Sync started' });
    await syncAmazonHighlights(); // Call the function to perform the sync

    // close tab
    sendNotification(sender.tab.id, "Sync done, closing tab in 3 seconds...", "success");
    setTimeout(() => {
      chrome.tabs.remove(sender.tab.id);
    }, 3000);
  }
});


function createElement(html) {
  return parseHTML(html).document;
}

const fetchFromAmazon = async (path, options) => {
  const headers = {
    "Cookie": cookieString,
    "User-Agent": navigator.userAgent,
    "Accept-Language": "en-US,en;q=0.9",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8",
    "Cache-Control": "no-cache"
  }

  const BASE_URL = "https://read.amazon.com/notebook";

  try {
    const response = await fetch(BASE_URL + path, {
      headers,
      method: "GET",
      ...options,
    });
    if (!response.ok) {
      throw new Error(`Failed to fetch Amazon Notebook: ${response.status}`);
    }
    return response.text();
  } catch (error) {
    console.error('Fetch error:', error);
    throw error; // Re-throw the error to be caught by the retry logic
  }
}


const log = (message) => {
  console.log(message);
  /* 
    fetch(SERVER_ADDR + "/log", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message,
        ts: new Date().toISOString(),
        user: syncProcess.userName,
        status: syncProcess.status,
      }),
    }) */
}

async function retryFetch(url, retries = MAX_RETRIES, delay = 1000) {
  for (let i = 0; i < retries; i++) {
    try {
      return await fetchFromAmazon(url, {});
    } catch (error) {
      console.log(error)
      if (i < retries - 1) {
        console.log(`Retrying... (${i + 1}/${retries})`);
        await new Promise(resolve => setTimeout(resolve, delay));
      } else {
        console.error('Max retries reached. Throwing error.');
        throw error; // Throw the error if max retries reached
      }
    }
  }
}
function sendNotification(tabId, message, type) {
  chrome.tabs.sendMessage(tabId, {
    action: "showNotification",
    message: message,
    type: type,
  });
}