"use strict";

// loads the service worker
// TODO use a library to make a great SW
require("./sw-installer");

// require("./rollbar");
require("./styles.scss");

const { Elm } = require("./Main");

var app = Elm.Main.init({ flags: {} });

app.ports.toJs.subscribe(data => {
    switch (data.tag) {
        case "RemoveAppShell":
            let rm = document.querySelector(".removable");
            if (rm) rm.remove();
            break;
        case "LogRollbar":
            fb.logger({
                source: "elm",
                message: data.payload
            });
            break;
        default:
            console.error(data);
    }
});

// F i r e b a s e

// get the non-SW config
import { firebaseConfig } from "./config/firebase-config";
// Initialise firebase using config data
firebase.initializeApp(firebaseConfig);

// Set up Elm to use Firebase handler
import fb from "./Firebase/fb";
app.ports.elmToFb.subscribe(msg =>
    fb.handler(msg, val => app.ports.fbToElm.send(val))
);
