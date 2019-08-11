"use strict";

// require("./rollbar");
require("./sw-installer");
require("bootstrap-loader");
require("./styles.scss");

import {firebaseConfig} from './firebase-config';

const {Elm} = require('./Main');

var app = Elm.Main.init({flags: {}});

// Once Elm is running, remove the existing 'appshell'
app.ports.removeAppShell.subscribe(() => {
    let rm = document.querySelector(".removable");
    if (rm) rm.remove();
});

// F i r e b a s e

// ********** C O N F I G
//console.log("Using project:", config.projectId);
//import config from "./Firebase/fb.config";
//firebase.initializeApp(config);

// Load main firebase handler using your config data

// Initialize Firebase
console.log("* firebase.initializeApp(firebaseConfig)")
firebase.initializeApp(firebaseConfig);

import fb from "./Firebase/fb";
// Finally, set up Elm to use Firebase handler
app.ports.elmToFb.subscribe(msg => fb.handler(msg, app.ports.fbToElm.send));

// rollbar
app.ports.rollbar.subscribe(msg => {
    fb.logger({
        source: "elm",
        message: msg
    });
});
