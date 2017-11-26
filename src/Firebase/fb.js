import fbmsg from './fbm';

// Elm message handler
function handler({message, payload}, fbToElm) {
    switch (message) {
        case "ListenAuthState":
            createAuthListener(fbToElm);
            break;
        case "RequestMessagingPermission":
            fbmsg.requestMessagingPermission(logger, fbToElm);
            break;
        // case "UnregisterMessaging":
        //     fbmsg.unregisterMessaging(logger, fbToElm);
        //     break;
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

function logger(msg) {
    let reg = new RegExp('hampton-xmas');

    if (reg.test(window.location.href)) {
        console.log("Sending to rollbar", msg);
        Rollbar.error(msg);
    } else {
        console.error("[logger]", msg);
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
    console.log("[createAuthListener] starting");
    firebase.auth()
        .onAuthStateChanged(function(user) {
            console.log("[createAuthListener]", user);

            if (user) {
                fbToElm(makeUserObject(user))
            } else {
                fbToElm({
                    message: "authstate",
                    payload: null
                });
            }
        });
}

function signin(email, password, fbToElm) {
    firebase.auth()
        .signInWithEmailAndPassword(email, password)
        .then(res => {
            console.log("Signin success", res);
        })
        .catch(function(err) {
            fbToElm({message: "error", payload: err});
            Rollbar.info(err);
        });
}

function register(email, password, fbToElm) {
    firebase.auth()
        .createUserWithEmailAndPassword(email, password)
        .then(res => {
            console.log("Register success", res);
        })
        .catch(function(err) {
            fbToElm({message: "error", payload: err});
            logger(err);
        });
}

// Use success here to send message back to Elm. Hopefully this will enable the client
// to go forward, as otherwise the authstate change does not seem always to be recorded
function signinGoogle(fbToElm) {
    console.log("[signinGoogle] start");
    var provider = new firebase.auth.GoogleAuthProvider();
    // firebase.auth().signInWithPopup(provider).then(function(result) {
    firebase.auth().signInWithRedirect(provider)
        .then(function(result) {
            console.log("Google signin successful")
            // This gives you a Google Access Token. You can use it to access the Google API.
            // var token = result.credential.accessToken;

            // Send user details back to Elm
            fbToElm(makeUserObject(result.user));
        })
        .catch(function(error) {
            console.log(error)
            logger(error);
        });
}


function signout(x) {
    firebase.auth()
        .signOut()
        .then(res => {
            console.log("signed out");
        });
}

function set(data) {
    firebase.database().ref(data.ref)
        .set(data.payload);
}

function remove(ref) {
    // console.log("removing ref:", ref);
    firebase.database().ref(ref)
        .remove();
}

function push(data) {
    firebase.database().ref(data.ref)
        .push(data.payload);
}

function subscribe(fbToElm, _ref) {
    firebase.database().ref(_ref)
        .on('value', snapshot => {
            fbToElm({
                message: "snapshot",
                payload: {
                    key: _ref,
                    value: snapshot.val()
                }
            });
        });
}

export default {
    createAuthListener, handler, logger
};
