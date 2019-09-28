const Rollbar = require("../rollbar");

// import helpers for messaging
// get the non-SW config
import { firebaseConfig } from "../assets/config/firebase-config";
// Initialise firebase using config data
firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// Elm message handler
function handler({ message, payload }, fbToElm) {
    console.log("[fb.js]", message, payload);
    switch (message) {
        case "ListenAuthState":
            createAuthListener(fbToElm);
            break;
        case "GetMessagingToken":
            // Attempt to get a mesaging token and return it to Elm
            getMessagingToken(fbToElm);
            break;
        case "signin":
            signin(payload.email, payload.password, fbToElm);
            break;
        case "register":
            register(payload.email, payload.password, fbToElm);
            break;
        case "signinGoogle":
            signinGoogle(fbToElm);
            break;
        case "signout":
            signout();
            break;
        case "subscribe":
            subscribe(fbToElm, payload);
            break;
        case "set":
            set(payload);
            break;
        case "update":
            update(payload);
            break;
        case "remove":
            remove(payload);
            break;
        case "push":
            push(payload);
            break;
        default:
            break;
    }
}

function makeUserObject(user) {
    return {
        message: "authstate",
        payload: {
            email: user.email,
            uid: user.uid,
            displayName: user.displayName,
            photoURL: user.photoURL,
            token: user.token
        }
    };
}

function createAuthListener(fbToElm) {
    // console.log("[createAuthListener] starting");
    firebase.auth().onAuthStateChanged(function(user) {
        console.log("[createAuthListener]", user);

        if (user) {
            fbToElm(makeUserObject(user));
        } else {
            fbToElm({
                message: "authstate",
                payload: null
            });
        }
    });
}

function signin(email, password, fbToElm) {
    firebase
        .auth()
        .signInWithEmailAndPassword(email, password)
        .then(res => {
            console.log("Signin success", res);
        })
        .catch(function(err) {
            fbToElm({ message: "error", payload: err });
            console.error(err);
            Rollbar.info(err);
        });
}

function register(email, password, fbToElm) {
    firebase
        .auth()
        .createUserWithEmailAndPassword(email, password)
        .then(res => {
            console.log("Register success", res);
        })
        .catch(function(err) {
            fbToElm({ message: "error", payload: err });
            logger(err);
        });
}

// Use success here to send message back to Elm. Hopefully this will enable the client
// to go forward, as otherwise the authstate change does not seem always to be recorded
function signinGoogle(fbToElm) {
    console.log("[signinGoogle] start");
    var provider = new firebase.auth.GoogleAuthProvider();
    // firebase.auth().signInWithPopup(provider).then(function(result) {
    firebase
        .auth()
        .signInWithRedirect(provider)
        .then(function(result) {
            console.log("Google signin successful");
            // This gives you a Google Access Token, result.credential.accessToken

            // Send user details back to Elm
            fbToElm(makeUserObject(result.user));
        })
        .catch(function(error) {
            logger(error);
            fbToElm({
                message: "Error",
                payload: error
            });
        });
}

function signout(x) {
    firebase
        .auth()
        .signOut()
        .then(res => {
            console.log("signed out");
        });
}

// set replaces object at ref
function set(data) {
    firebase
        .database()
        .ref(data.ref)
        .set(data.payload);
}

function update(data) {
    firebase
        .database()
        .ref(data.ref)
        .update(data.payload);
}

function remove(ref) {
    // console.log("removing ref:", ref);
    firebase
        .database()
        .ref(ref)
        .remove();
}

function push(data) {
    firebase
        .database()
        .ref(data.ref)
        .push(data.payload);
}

function subscribe(fbToElm, _ref) {
    console.log("subscribe", _ref);
    firebase
        .database()
        .ref(_ref)
        .on("value", snapshot => {
            console.log(snapshot.val());
            fbToElm({
                message: "snapshot",
                payload: {
                    key: _ref,
                    value: snapshot.val()
                }
            });
        });

    // adds ability to keep track of whether online
    firebase
        .database()
        .ref(_ref)
        .child(".info/connected")
        .on("value", function(connectedSnap) {
            if (connectedSnap.val() === true) {
                // console.log("/* we're connected! */");
            } else {
                // console.log("/* we're disconnected! */");
            }
        });
}

function logger(msg) {
    let reg = new RegExp("hampton-xmas");

    if (reg.test(window.location.href)) {
        console.log("Sending to rollbar", msg);
        Rollbar.error(msg);
    } else {
        console.error("[logger]", msg);
    }
}

/*
 * MESSAGING
 */

// Code to request permission to notify.
// If user accepts notifications, we get a token which we ....

const CFError = "CFError";

const vapidKey =
    "BHjECplRVszZL2J92EptDzETrwr1YjPWx9XeKNyR3qUBb0iVT3mGPUrV2unnJCtdi9OUNF6IiQIKOTOdUUjl7Gk";

// As Elm loads it requests the messagin token,
// We will use that hook as the moment to set up messaging envent listeners
function getMessagingToken(cb) {
    // next line essential for getToken to work
    messaging.usePublicVapidKey(vapidKey);

    Notification.requestPermission().then(permission => {
        if (permission === "granted") {
            console.log("Notification permission granted.");
            return messaging.getToken().then(function(currentToken) {
                if (currentToken) {
                    let obj = {
                        message: "MessagingToken",
                        payload: currentToken
                    };
                    console.log(obj);
                    cb(obj);
                } else {
                    cb({
                        message: "Error",
                        payload: "getToken returned no data"
                    });
                }
            });
        } else {
            console.log("Unable to get permission to notify.");
            cb({
                message: "NotificationsRefused",
                payload: "Unable to get permission to notify"
            });
        }
    });
    // Handle incoming messages. Called when:
    // - a message is received while the app has focus
    // - the user clicks on an app notification created by a service worker
    //   `messaging.setBackgroundMessageHandler` handler.
    messaging.onMessage(payload => {
        console.log("[getMessagingToken] Message received. ", payload);
        // ...
    });
    // event handlers
    messaging.onTokenRefresh(() => {
        messaging
            .getToken()
            .then(refreshedToken => {
                console.log("[getMessagingToken] Token refreshed.");
            })
            .catch(err => {
                console.log("Unable to retrieve refreshed token ", err);
            });
    });
}

/*
 * EXPORTS
 */

export default {
    createAuthListener,
    handler,
    logger
};
