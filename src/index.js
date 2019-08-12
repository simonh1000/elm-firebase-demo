"use strict";

// require("./rollbar");
require("./sw-installer");
require("bootstrap-loader");
require("./styles.scss");

import {firebaseConfig} from './config/firebase-config';

const {Elm} = require('./Main');

var app = Elm.Main.init({flags: {}});

// Once Elm is running, remove the existing 'appshell'
app.ports.removeAppShell.subscribe(() => {
    let rm = document.querySelector(".removable");
    if (rm) rm.remove();
});

// F i r e b a s e

// Initialise firebase using config data
console.log("* firebase.initializeApp(firebaseConfig)")
firebase.initializeApp(firebaseConfig);

// Set up Elm to use Firebase handler
import fb from "./Firebase/fb";
app.ports.elmToFb.subscribe(msg => fb.handler(msg, app.ports.fbToElm.send));

// rollbar
app.ports.rollbar.subscribe(msg => {
    fb.logger({
        source: "elm",
        message: msg
    });
});
