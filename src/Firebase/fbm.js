import config from "./fb.config";

// See also /assets/firebase-messaging.js

// Triggr pop-up that asks for permission
function requestMessagingPermission(userId, logger, cb) {
    // Create within function because firebase may not otherwise be initialised
    const messaging = firebase.messaging();

    messaging
        .requestPermission()
        .then(function() {
            console.log("[fbm] Notification permission granted.");
            return registerForUpdates(userId, logger);
        })
        .then(({msg, payload}) => {
            console.log(msg, payload);
            cb(msg);
        })
        .catch(err => {
            logger({
                "message": "[fbm] Error",
                "payload": err
            });
        });

    messaging.onMessage(function(payload) {
        console.log("[fbm] Message received. ", payload);
        // Probaly need to renew subscription here
        cb({
            message: "token-refresh",
            payload: payload
        });
    });
}

// Inspired by https://github.com/firebase/quickstart-js/blob/master/messaging/index.html
// Get Instance ID token. Initially this makes a network call, once retrieved
// subsequent calls to getToken will return from cache.
function registerForUpdates(userId, logger) {
    const messaging = firebase.messaging();
    console.log("[fbm userId]", userId);

    // This method returns null when permission has not been granted.
    return messaging.getToken()
        .then(function(currentToken) {
            if (currentToken) {
                // Register for topic: presents
                // Send token to Cloud Function, which uses it to setup messaging subscription

                var myHeaders = new Headers();
                myHeaders.append("Content-Type", "application/json");

                let body = JSON.stringify({
                    "userId": userId,
                    "token": currentToken
                });
                var options = {
                    "method": "POST",
                    "headers": myHeaders,
                    "body": body
                };
                console.log("[fbm.registerForUpdates: currentToken]", currentToken, options);

                return fetch(config.serverUrl, options)
                    .then(function(response) {
                        if (response.status < 200 || response.status > 400) {
                            return Promise.reject({msg: "[fbm.registerForUpdates] Bad response", payload: response});
                        }
                        console.log("[fbm.registerForUpdates] Success", response);
                        return {msg: "[fbm.registerForUpdates] Success", payload: response};
                    });
            } else {
                // Show permission request.
                return Promise.resolve({msg: "[fbm] No Instance ID token available. Request permission to generate one.", payload: null});
            }
        })
}

function unregisterMessaging(logger, fbToElm) {
    console.log("Attempting to unsubcribe");
    return firebase.messaging()
        .getToken()
        .then(function(currentToken) {
            if (currentToken) {
              // Make request to cloud function
              let serverUrl = config.serverUrl
                // DELETE  https://iid.googleapis.com/v1/web/iid/REGISTRATION_TOKEN
                // let url = `https://iid.googleapis.com/v1/web/iid/${currentToken}`;
                //
                // var options = {
                //     method: "DELETE"
                // };
                // var myRequest = new Request(url, options);
                // return fetch(myRequest);
            }
        })
        .then(response => {
            console.log("unregisterMessaging success", response);
        })
        .catch(err => {
            logger({ function: "unregisterMessaging", error: err });
        });
}

export default {
    requestMessagingPermission, unregisterMessaging
};
