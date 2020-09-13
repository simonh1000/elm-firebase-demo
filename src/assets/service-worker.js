import { precacheAndRoute } from "workbox-precaching";
import { registerRoute } from "workbox-routing";
import { CacheFirst, NetworkFirst } from "workbox-strategies";

console.log(`Setting up cache 🎉`);

var cdn = ["https://www.gstatic.com/firebasejs/7.20.0/firebase-app.js"];
// The precache manifest lists the names of the files that were processed by webpack
// and that end up in your dist folder. Does not include files that were simply copied
precacheAndRoute(self.__WB_MANIFEST.concat([]));

// TODO check whether this caches the firebase cdn code
registerRoute(
    /\.js$/,
    new NetworkFirst({
        cacheName: "xmas-js",
    })
);

// Also cache copied image files
registerRoute(
    // Cache image files.
    /\.(?:png|jpg|jpeg|svg|gif)$/,
    // Use the cache if it's available.
    new CacheFirst({
        // Use a custom cache name.
        cacheName: "xmas-images",
    })
);

// enables a new SW to replace an existing one when a user clicks OK to do so
addEventListener("message", (event) => {
    console.log("[service-worker.js] message", event.data);
    if (event.data && event.data.type === "SKIP_WAITING") {
        return skipWaiting();
    }
});
