window.addEventListener("isNotebaseInstalled", () => {
  // Respond back to the page that the extension is installed
  window.dispatchEvent(new CustomEvent("notebaseExtensionDetected"));
});

const token = localStorage.getItem("at");

if (token) {
  chrome.runtime.sendMessage({ action: "sendToken", token: token });
}