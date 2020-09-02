"use strict";

import { Workbox, messageSW } from "workbox-window";

// import { Rollbar } from "./js/rollbar";
require("./styles.scss");
const { Elm } = require("./Main");

const phase2 = "2020-11-01";
// CLOUD_URL or EMULATOR_URL
const cloudFunction = process.env.CLOUD_URL;
// from package.json (via webpack.config)
console.log("** VERSION **", VERSION);

// Register Service Worker
if ("serviceWorker" in navigator) {
    var wb = new Workbox("/service-worker.js");
    let registration;

    // we want to check periodically whether there is an update to the service worker
    // e.g. for a change in the cache name, indicating an update in the underlying code base
    setInterval(() => {
        wb.update();
    }, 5000);

    const showSkipWaitingPrompt = (event) => {
        console.log("registration", registration);
        // `event.wasWaitingBeforeRegister` will be false if this is
        // the first time the updated service worker is waiting.
        // When `event.wasWaitingBeforeRegister` is true, a previously
        // updated service worker is still waiting.
        // You may want to customize the UI prompt accordingly.

        // Assumes your app has some sort of prompt UI element
        // that a user can either accept or reject.
        const createUIPrompt = (r) => r;
        var prompt = createUIPrompt({
            onAccept: async () => {
                console.log("running onAccept");
                // Assuming the user accepted the update, set up a listener
                // that will reload the page as soon as the previously waiting
                // service worker has taken control.
                wb.addEventListener("controlling", (event) => {
                    console.log("controlling");
                    window.location.reload();
                });

                if (registration && registration.waiting) {
                    // Send a message to the waiting service worker,
                    // instructing it to activate.
                    // Note: for this to work, you have to add a message
                    // listener in your service worker. See below.
                    console.log("Sending SKIP_WAITING");
                    messageSW(registration.waiting, { type: "SKIP_WAITING" });
                }
            },

            onReject: () => {
                prompt.dismiss();
            },
        });

        console.log("wasWaitingBeforeRegister", event.wasWaitingBeforeRegister);
        const msg = event.wasWaitingBeforeRegister
            ? "An existing SW is still waiting to install"
            : "A new version of the App exists. Click to update to the latest version";
        if (window.confirm(msg)) {
            prompt.onAccept();
        }
    };

    // Add an event listener to detect when the registered
    // service worker has installed but is waiting to activate.
    wb.addEventListener("waiting", showSkipWaitingPrompt);
    wb.addEventListener("externalwaiting", showSkipWaitingPrompt);

    wb.register().then((r) => (registration = r));
}

// E L M   I N I T
var app = Elm.Main.init({
    flags: {
        cloudFunction,
        version: VERSION,
        phase2,
    },
});

app.ports.toJs.subscribe((data) => {
    switch (data.tag) {
        case "LogRollbar":
            console.error(data.payload);
            // Rollbar.info({
            //     source: "elm",
            //     message: data.payload,
            // });
            break;
        case "LogConsole":
            console.log(data.payload);
            break;
        case "LogError":
            console.error(data.payload);
            break;
        default:
            console.error(data);
    }
});

// F i r e b a s e

// Set up Elm to use Firebase handler
import fb from "./Firebase/fb";

app.ports.elmToFb.subscribe((msg) =>
    fb.handler(msg, (val) => app.ports.fbToElm.send(val))
);
