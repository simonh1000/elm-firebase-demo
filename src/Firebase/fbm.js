// imports the config - not needed with modern firebase
//import config from "./fb.config";

const CFError = "CFError"
// See also /assets/firebase-messaging.js

function makeRequest(userId, token) {
    var myHeaders = new Headers();
    myHeaders.append("Content-Type", "application/json");

    let body = JSON.stringify({
        "userId": userId,
        "token": token
    });
    return {
        "method": "POST",
        "headers": myHeaders,
        "body": body
    };
}

// Trigger pop-up that asks for permission
function requestMessagingPermission(userId, logger, cb) {
    // Create within function because firebase may not otherwise be initialised
    const messaging = firebase.messaging();

    messaging
        .requestPermission()
        .then( () => connectNotificationHandler(logger, "subscribe", userId) )
        .then( body => cb(body) )
        .catch(err => {
            logger({
                "message": CFError,
                "payload": err
            });
        });

    messaging.onTokenRefresh(function() {
        messaging.getToken().then(function(refreshedToken) {
            console.log('Token refreshed.');
        }).catch(function(err) {
            console.log('Unable to retrieve refreshed token ', err);
        });
    });

    // Handle messages received while on the app page
    messaging.onMessage(function(payload) {
        console.log("[fbm] onMessage received, but unhandled.", payload);
    });
}

function connectNotificationHandler(logger, mode, userId) {
    const messaging = firebase.messaging();

    // This method returns null when permission has not been granted.
    return messaging.getToken()
        .then(function(currentToken) {
            if (currentToken) {
                let options = makeRequest(userId, currentToken);
                console.log("[fbm.connectNotificationHandler: currentToken]", mode, options);

                // Send token to Cloud Function, which uses it to setup messaging subscription
                return fetch(config.serverUrl + mode, options)
                    .then(function(response) {
                        if (response.status < 200 || response.status > 400) {
                            return Promise.reject({message: "CFError", payload: response});
                        }
                        console.log("[connectNotificationHandler success]", mode, response);
                        return response.json();
                    });
            } else {
                // Let front end inform user that they have blocked notices
                return Promise.resolve({message: "NoUserPermission", payload: null});
            }
        })
}

function unregisterMessaging(userId, logger, fbToElm) {
    console.log("Attempting to unsubscribe");
    connectNotificationHandler(logger, "unsubscribe", userId)
        .then(response => {
            console.log("unregisterMessaging success", response);
            fbToElm(response);
        })
        .catch(err => {
            logger({ function: "unregisterMessaging", "error": err });
            fbToElm({
                message: CFError,
                payload: err
            })
        });
}

export default {
    requestMessagingPermission, unregisterMessaging
};
