// Give the service worker access to Firebase Messaging.
// Note that you can only use Firebase Messaging here, other Firebase libraries
// are not available in the service worker.
importScripts('https://www.gstatic.com/firebasejs/3.9.0/firebase-app.js');
importScripts('https://www.gstatic.com/firebasejs/3.9.0/firebase-messaging.js');
importScripts('/Firebase/fbsw.config.js');

// Initialize the Firebase app in the service worker by passing in the config.messagingSenderId.
firebase.initializeApp({
    'messagingSenderId': self.config.messagingSenderId
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages.
const messaging = firebase.messaging();

// SW will handle background messages while app handles foreground ones
messaging.setBackgroundMessageHandler(function(payload) {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    // click_action should open app - not sure that click_action has any effect at all
    const notificationTitle = 'Presents Update for ' + payload.data.person;
    const notificationOptions = {
        body: 'Added new idea: ' + payload.data.present,
        icon: '/images/icons/present-192x192.png',
        click_action: 'https://hampton-xmas.firebaseapp.com/'
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});

// Do something with a click
self.addEventListener('notificationclick', function(event) {
    console.log('[firebase-messaging-sw] Notification click Received.');

    event.notification.close();
    // Open the app
    event.waitUntil(clients.openWindow('https://hampton-xmas.firebaseapp.com/'));
});
