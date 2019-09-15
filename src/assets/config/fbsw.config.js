// DO NOT DELETE
// replicates the messagingSenderId from firebase-config so that the service worker can access it
// This script is loaded the service worker created by assets/firebase-messaging-sw
// it therefore uses self
// See https://console.firebase.google.com/project/hampton-xmas/settings/cloudmessaging/

var dev = {
    messagingSenderId: "560494585640",
    url: "https://xmas2019.firebaseapp.com/"
};

var prod = {
    messagingSenderId: "560494585640",
    url: "https://hampton-xmas.firebaseapp.com/"
};

// self is the global context for a web worker
self.config = self.config || prod;
// console.log("[fbsw.config]", self.config.url)
