import { sendDataToServer, getNotebaseCookies } from './utils.js';

const getObjectType = (data) => {
  const { mediaType } = data

  if (mediaType) {
    return mediaType;
  }

  if (data.selectionText) return "text";
  if (data.linkUrl) return "link";

  return "unknown";
}

export const saveObject = async (data, tab) => {
  const url = data.page?.url ?? tab.url;
  const type = getObjectType(data);

  console.log(`saving object of type ${type}`, data);

  const contentHandler = {
    "text": data.selectionText,
    "image": data.srcUrl,
    "video": data.srcUrl,
    "yt-video": data.videoURL,
    "link": data.linkUrl,
    "unknown": data,
  }

  const objData = {
    type,
    content: contentHandler[type],
    url,
    title: data.title ?? tab.title,
    metadata: data.metadata,
  }

 /*  const notebaseCookies = await getNotebaseCookies()
  if (!notebaseCookies) {
    console.log("Failed to get Notebase cookies, aborting sync");
    return
  } */

  return createObject(objData, tab, '');
}

async function createObject(obj, tab, at) {
  try {
    const response = await sendDataToServer("/capture/web", obj, at);

    console.log('created object', response);
    sendNotification(tab.id, `${capitalizeFirstLetter(obj.type)} saved to Notebase`, "success");

    return response;
  } catch (error) {
    console.error('error creating object', error);
    sendNotification(tab.id, "Error saving to Notebase", "error");
  }
}

function sendNotification(tabId, message, type) {
  chrome.tabs.sendMessage(tabId, {
    action: "showNotification",
    message: message,
    type: type,
  });
}

function capitalizeFirstLetter(string) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}