import config from "./fb.config";

// See also /assets/firebase-messaging.js

function requestMessagingPermission(cb) {
    const messaging = firebase.messaging();
    messaging.requestPermission()
        .then(function() {
            console.log('[fbm] Notification permission granted.');
            return resigterForUpdates();
        })
        .catch(function(err) {
            console.log('[fbm] Unable to get permission to notify.', err);
        });

    messaging.onMessage(function(payload) {
        console.log("[fbm] Message received. ", payload);
        cb({
            message: "OnMessage",
            payload: payload
        })
    });
}

function resigterForUpdates() {
    const messaging = firebase.messaging();

    // Get Instance ID token. Initially this makes a network call, once retrieved
    // subsequent calls to getToken will return from cache.
    return messaging.getToken()
        .then(function(currentToken) {
            if (currentToken) {
                // Register for topic: presents
                let topic = "presents"
                let url = `https://iid.googleapis.com/iid/v1/${currentToken}/rel/topics/${topic}`;
                // console.log("[fbm] ", config.serverKey);
                var myHeaders = new Headers();
                myHeaders.append("Content-Type", "application/json");
                myHeaders.append("Authorization", "key=" + config.serverKey);
                var myInit = {
                    method: 'POST',
                    headers: myHeaders,
                    mode: 'cors',
                    cache: 'default',
               };
               var myRequest = new Request(url, myInit);
               return fetch(myRequest)
                   .then(function(response) {
                        if (response.status !== 200) {
                            return console.log("[fbm] Bad response", response);
                        }

                        return console.log("[fbm] Registered for topic:", topic);
                   })
                   .catch( (err) => {
                       console.log("[fbm] Error registering for topic", err)
                   });
            } else {
                // Show permission request.
                console.log('[fbm] No Instance ID token available. Request permission to generate one.');
            }
        })
        .catch(function(err) {
            console.error('An error occurred while retrieving token.', err);
        });
}

export default {
    requestMessagingPermission
};
