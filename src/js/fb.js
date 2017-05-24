function createAuthListener(cb) {
    firebase.auth()
        .onAuthStateChanged(function(user) {
            console.log("auth state change", user);
            // let res = user || {error: ""};
            let res;
            if (user) {
                res = {
                    email: user.email,
                    uid: user.uid,
                    displayName: user.displayName,
                    photoURL: user.photoURL
                }
            } else {
                res = {error: ""};
            }
            cb(res);
        });
}

// Elm message handler
function handler({message, payload}, cb, fbToElm) {
    switch (message) {
        case "signin":
            signin(payload.email, payload.password, fbToElm);
            break;
        case "register":
            register(payload.email, payload.password);
            break;
        case "signinGoogle":
            signinGoogle();
            break;
        case "signout":
            signout();
            break;
        case "subscribe":
            subscribe(cb, payload);
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


function signin(email, password, fbToElm) {
    firebase.auth()
        .signInWithEmailAndPassword(email, password)
        .then(res => {
            console.log("Signin success", res);
        })
        .catch(function(err) {
            fbToElm({message: "error", payload: err});
            console.error(err);
        });
}

function register(email, password) {
    firebase.auth()
        .createUserWithEmailAndPassword(email, password)
        .then(res => {
            console.log("Signin success", res);
        })
        .catch(function(error) {
            console.error(error);
        });
}

function signinGoogle() {
    var provider = new firebase.auth.GoogleAuthProvider();
    firebase.auth().signInWithPopup(provider).then(function(result) {
        // This gives you a Google Access Token. You can use it to access the Google API.
        var token = result.credential.accessToken;
        // The signed-in user info.
        var user = result.user;
        // ...
    }).catch(function(error) {
        // Handle Errors here.
        var errorCode = error.code;
        var errorMessage = error.message;
        // The email of the user's account used.
        var email = error.email;
        // The firebase.auth.AuthCredential type that was used.
        var credential = error.credential;
        // ...
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
    console.log("removing ref:", ref);
    firebase.database().ref(ref)
        .remove();
}

function push(data) {
    firebase.database().ref(data.ref)
        .push(data.payload);
}

function subscribe(onSnapshot, _ref) {
    firebase.database().ref(_ref)
        .on('value', snapshot => {
            let res = {
                key: _ref,
                value: snapshot.val()
            };
            onSnapshot(res);
        });
}
export default {
    createAuthListener, handler
};
