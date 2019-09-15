// Code to request permission to notify.
// If user accepts notifications, we get a token which we ....

const vapidKey =
    "BGpd5x70Enyr87_JlcKklWNkG63-8zqlx0HqGstjfeDo3dw0D2e2aW0Hbx4YteL8nXH3-ofuBe-q54sQ3pPSJmA";

function requestMessagingPermission(userId, logger, cb) {
    // Retrieve Firebase Messaging object.
    const messaging = firebase.messaging();

    messaging.usePublicVapidKey(vapidKey);

    // Trigger pop-up that asks for permission
    Notification.requestPermission()
        .then(permission => {
            if (permission === "granted") {
                console.log("Notification permission granted.");
                return Promise.resolve("Permission granted");
            } else {
                console.log("Unable to get permission to notify.");
                return Promise.reject("Permission to notify rejected");
            }
        })
        .then(() => connectNotificationHandler(logger, "subscribe", userId))
        .then(body => cb(body))
        .catch(err => {
            logger({
                message: CFError,
                payload: err
            });
        });

    // Handle incoming messages. Called when:
    // - a message is received while the app has focus
    // - the user clicks on an app notification created by a service worker
    //   `messaging.setBackgroundMessageHandler` handler.
    messaging.onMessage(payload => {
        console.log("Message received. ", payload);
        // ...
    });
    // event handlers
    messaging.onTokenRefresh(() => {
        messaging
            .getToken()
            .then(refreshedToken => {
                console.log("Token refreshed.");
            })
            .catch(err => {
                console.log("Unable to retrieve refreshed token ", err);
            });
    });
}

function connectNotificationHandler(logger, mode, userId) {
    // This method returns null when permission has not been granted.
    return messaging.getToken().then(function(currentToken) {
        if (currentToken) {
            console.log(
                "[fbm.connectNotificationHandler: currentToken]",
                mode,
                options
            );
            return sendTokenToServer(config, currentToken);
        } else {
            // Let front end inform user that they have blocked notices
            return Promise.resolve({
                message: "NoUserPermission",
                payload: null
            });
        }
    });
}

function sendTokenToServer(config, currentToken) {
    let options = makeRequest(userId, currentToken);
    // Send token to Cloud Function, which uses it to setup messaging subscription
    return fetch(config.serverUrl + mode, options).then(function(response) {
        if (response.status <= 200 || response.status >= 400) {
            return Promise.reject({
                message: "CFError",
                payload: response
            });
        }
        console.log("[connectNotificationHandler success]", mode, response);
        return response.json();
    });
}
function unregisterMessaging(userId, logger, fbToElm) {
    return "success";
}

export default {
    requestMessagingPermission,
    unregisterMessaging
};
