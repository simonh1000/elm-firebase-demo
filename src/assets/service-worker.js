import { precacheAndRoute } from "workbox-precaching";

console.log(`Setting up cache 🎉`);

// The precache manifest lists the names of the files that were processed by webpack and that end up in your dist folder.
precacheAndRoute(self.__WB_MANIFEST);

// enables a new SW to replace an existing one when a user clicks OK to do so
addEventListener("message", (event) => {
    console.log("[service-worker.js] message", event.data);
    if (event.data && event.data.type === "SKIP_WAITING") {
        skipWaiting();
    }
});
