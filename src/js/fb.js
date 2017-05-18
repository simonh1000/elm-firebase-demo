function createAuthListener(onAuthStateChanged) {
    firebase.auth()
    .onAuthStateChanged(function(user) {
        console.log("auth state change", user);
        let res = (user) ? {email: user.email, uid: user.uid} : {error: ""};
        onAuthStateChanged(res);
    });
}

function signin(email, password) {
    firebase.auth()
        .signInWithEmailAndPassword(email, password)
        .then(res => {
            console.log("Signin success", res);
        })
        .catch(function(error) {
            console.error(error);
        });
}

function register( email, password) {
    firebase.auth()
        .createUserWithEmailAndPassword(email, password)
        .then(res => {
            console.log("Signin success", res);
        })
        .catch(function(error) {
            console.error(error);
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
                value :  snapshot.val()
            };
            onSnapshot(res);
        });
}
export default  {
    signin, register, signout, push, subscribe, set, createAuthListener, remove
};
