// Installs the service worker at /src/assets/service-worker.js

// Check that service workers are supported
if ("serviceWorker" in navigator) {
    // Use the window load event to keep the page load performant
    window.addEventListener("load", () => {
        navigator.serviceWorker.register("/service-worker.js");
    });
}
