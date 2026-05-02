const SERVER_ADDR = "http://localhost:4000/api";

const isDev = true
const APP_URL = isDev ? "http://localhost:3000" : "https://notebase.org";

export async function sendDataToServer(path, data, at) {
  return fetch(SERVER_ADDR + path, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + at
    },
    body: JSON.stringify({ ...data })
  })
    .then(response => response)
    .then(result => {
      console.log("Data successfully sent to server:", result);

      chrome.notifications.create({
        type: "basic",
        iconUrl: "icons/add.png",
        title: "Digital note saved",
        message: "Your note has been saved to Notebase",
      });

    })
    .catch(error => {
      console.error("Error sending data to server:", error);
    });
}

export function getNotebaseCookies() {
  return new Promise((resolve, reject) => {
    chrome.cookies.get({ url: APP_URL, name: 'sAccessToken' },
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