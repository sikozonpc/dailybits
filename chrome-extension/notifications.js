function showCustomNotification(message, type = "success") {
  const notification = document.createElement("div");
  notification.classList.add("custom-notification", type);
  notification.innerHTML = `
    <div class="notification-content">
      <span>${message}</span>
    </div>
  `;

  document.body.appendChild(notification);

  setTimeout(() => {
    notification.classList.add("visible");
    setTimeout(() => {
      notification.classList.remove("visible");
      setTimeout(() => notification.remove(), 300);
    }, 3000); // Display for 3 seconds
  }, 100);
}

chrome.runtime.onMessage.addListener((request) => {
  if (request.action === "showNotification") {
    showCustomNotification(request.message, request.type);
  }
});