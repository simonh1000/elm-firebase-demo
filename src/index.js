"use strict";

import { Workbox, messageSW } from "workbox-window";

// Rollbar currently included in head of index.html to allow it to attach to global scope
// import { Rollbar } from "./assets/js/rollbar";

require("./styles.scss");
const { Elm } = require("./Main");

const phase2 = "2020-11-01";

// For testing locally
// const cloudFunction = process.env.EMULATOR_URL;
const cloudFunction = process.env.CLOUD_URL;

// from package.json (via webpack.config)
console.log("** VERSION **", VERSION);

// Register Service Worker
// if ("serviceWorker" in navigator) {
let wb = new Workbox("/service-worker.js");
let registration;

// we want to check periodically whether there is an update to the service worker
// e.g. for a change in the cache name, indicating an update in the underlying code base
document.addEventListener("visibilitychange", function () {
    if (document.visibilityState === "visible") {
        console.log("[visibilitychange] Checking for new SW");
        wb.update();
    }
});

// Event handler for waiting/externalwaiting
const showSkipWaitingPrompt = (event) => {
    // `event.wasWaitingBeforeRegister` will be false if this is
    // the first time the updated service worker is waiting.
    // When `event.wasWaitingBeforeRegister` is true, a previously
    // updated service worker is still waiting.
    // You may want to customize the UI prompt accordingly.

    console.log("[showSkipWaitingPrompt] wasWaitingBeforeRegister", event);
    // console.log("wasWaitingBeforeRegister", event.wasWaitingBeforeRegister);
    // const msg = event.wasWaitingBeforeRegister
    //     ? "An existing SW is still waiting to install"
    //     : "A new version of the App exists. Click to update to the latest version";
    // if (window.confirm(msg)) {
    //     prompt.onAccept();
    // }
    app.ports.fromJs.send({
        tag: "NewCode",
        payload: !!event.wasWaitingBeforeRegister,
    });
};

// if (window.location.host.indexOf("localhost") > -1) {
// Add an event listener to detect when the registered
// service worker has installed but is waiting to activate.
wb.addEventListener("waiting", showSkipWaitingPrompt);
wb.addEventListener("externalwaiting", showSkipWaitingPrompt);

wb.register().then((r) => (registration = r));
// }
// }

// E L M   I N I T
const app = Elm.Main.init({
    flags: {
        cloudFunction,
        version: VERSION,
        phase2,
    },
});

app.ports.toJs.subscribe((data) => {
    switch (data.tag) {
        case "LogRollbar":
            if (location.host.indexOf("localhost") > -1) {
                console.error(data.payload);
            } else {
                Rollbar.error("elm", data.payload);
            }
            break;
        case "LogError":
            console.error(data.payload);
            break;
        case "SkipWaiting":
            onAccept().catch((err) => console.error(err));
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

// Service worker support
async function onAccept() {
    // The user accepted the update. We are going to tell the waiting service to worker to "SKIP_WAITING"
    // This will lead it to take control. We will listen for the "controlling" event, and
    // when received, we reload the page so that the new SW is used.
    wb.addEventListener("controlling", (event) => {
        console.log("[onAccept] event controlling => reload screen");
        window.location.reload();
    });

    if (registration && registration.waiting) {
        // Send a message to the waiting service worker,
        // instructing it to activate.
        // See also the message listener in service-worker.js
        console.log("[onAccept] Sending SKIP_WAITING");
        return messageSW(registration.waiting, { type: "SKIP_WAITING" });
    }
    return Promise.resolve("No registration");
}
