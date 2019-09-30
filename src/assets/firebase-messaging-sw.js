// Part of the Service Worker code

// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here, other Firebase libraries
// are not available in the service worker.
importScripts("https://www.gstatic.com/firebasejs/6.3.4/firebase-app.js");
importScripts("https://www.gstatic.com/firebasejs/6.3.4/firebase-messaging.js");

// Loads the SW version of the config
importScripts("/config/fbsw.config.js");

// Initialize the Firebase app in the service worker by passing in the config.messagingSenderId.
firebase.initializeApp({
    messagingSenderId: self.config.messagingSenderId
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

// SW will handle background messages while app handles foreground ones
messaging.setBackgroundMessageHandler(function(payload) {
    // console.log(
    //     "[firebase-messaging-sw.js] Received background message ",
    //     payload
    // );
    // Don't show any notifications before ....
    let endPhase1 = new Date("1 nov 2019");
    let now = new Date();

    const notificationTitle = "Presents update: " + payload.data.person;
    const notificationOptions = {
        body: (now < endPhase1)
            ? "Details available in November"
            : "Suggests: " + payload.data.present,
        icon: "./images/icons/icon-192x192.png"
    };

    return self.registration.showNotification(
        notificationTitle,
        notificationOptions
    );
});

// Do something with a click
self.addEventListener("notificationclick", function(event) {
    event.notification.close();
    // Open the app
    event.waitUntil(clients.openWindow(self.config.ur));
});
