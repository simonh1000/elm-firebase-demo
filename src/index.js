"use strict";

// require("./rollbar");
require("./sw-installer");

require("./styles.scss");


import {firebaseConfig} from './config/firebase-config';

const {Elm} = require('./Main');

var app = Elm.Main.init({flags: {}});

app.ports.toJs.subscribe(data => {
    switch(data.tag) {
        case "RemoveAppShell":
            let rm = document.querySelector(".removable");
            if (rm) rm.remove();
            break;
        case "LogRollbar":
            fb.logger({
                source: "elm",
                message: data.payload
            });
            break
        default:
            console.error(data);
    }
});


// F i r e b a s e

// Initialise firebase using config data
console.log("* firebase.initializeApp(firebaseConfig)")
firebase.initializeApp(firebaseConfig);

// Set up Elm to use Firebase handler
import fb from "./Firebase/fb";
app.ports.elmToFb.subscribe(msg => fb.handler(msg, app.ports.fbToElm.send));
