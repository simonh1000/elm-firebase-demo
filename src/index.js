"use strict";

// this will instantiate the service worker
// bulk of the content of the service worker is in src/assets/service-worker.js
require("./js/sw-installer");

import { Rollbar } from "./js/rollbar";

require("./styles.scss");

const { Elm } = require("./Main");

// CLOUD_URL or EMULATOR_URL
var app = Elm.Main.init({
    flags: process.env.CLOUD_URL
});

app.ports.toJs.subscribe(data => {
    switch (data.tag) {
        case "LogRollbar":
            Rollbar.info({
                source: "elm",
                message: data.payload
            });
            break;
        default:
            console.error(data);
    }
});

// F i r e b a s e

// Set up Elm to use Firebase handler
import fb from "./Firebase/fb";
app.ports.elmToFb.subscribe(msg =>
    fb.handler(msg, val => app.ports.fbToElm.send(val))
);
