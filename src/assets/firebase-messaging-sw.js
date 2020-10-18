// This Service Worker is required by Firebase and must have this name

// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here, other Firebase libraries
// are not available in the service worker.
importScripts("https://www.gstatic.com/firebasejs/6.3.5/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/6.3.5/firebase-messaging.js");

// Loads the SW version of the config
importScripts("/config/fbsw.config.js");
let endPhase1 = new Date("1 nov 2020");

// Initialize the Firebase app in the service worker by passing in the config.messagingSenderId.
firebase.initializeApp({
    messagingSenderId: self.config.messagingSenderId,
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

// SW will handle background messages while app handles foreground ones
messaging.setBackgroundMessageHandler(function (payload) {
    // console.log(
    //     "[firebase-messaging-sw.js] Received background message",
    //     payload
    // );
    // Don't show any notifications before ....
    let elems = payload.data.person
        ? mkPresent(payload.data)
        : mkCustom(payload.data);

    return self.registration.showNotification(elems.title, elems.options);
});

function mkPresent(data) {
    let now = new Date();
    let title = "Presents update: " + data.person.split(" ")[0];
    let options = {
        body:
            now < endPhase1
                ? "Details available November"
                : "Suggests: " + data.present,
        icon: "./images/icons/icon-192x192.png",
    };
    return { title, options };
}

function mkCustom(data) {
    let title = "Xmas 2020 update";
    let options = {
        body: data.notification,
        icon: "./images/icons/icon-192x192.png",
    };
    return { title, options };
}
// Do something with a click
self.addEventListener("notificationclick", function (event) {
    event.notification.close();
    // Open the app
    event.waitUntil(clients.openWindow(self.config.url));
});
