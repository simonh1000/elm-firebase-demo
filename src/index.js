"use strict";

// this will instantiate the service worker
// bulk of the content of the service worker is in src/assets/service-worker.js
require("./sw-installer");

import { Rollbar} from "./rollbar";

require("./styles.scss");

const { Elm } = require("./Main");

var app = Elm.Main.init({ flags: "https://us-central1-hampton-xmas2019.cloudfunctions.net/" });

app.ports.toJs.subscribe(data => {
    switch (data.tag) {
        case "RemoveAppShell":
            let rm = document.querySelector(".removable");
            if (rm) rm.remove();
            break;
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
