importScripts(
    "https://storage.googleapis.com/workbox-cdn/releases/5.1.2/workbox-sw.js"
);

if (workbox) {
    console.log(`Yes! Is Workbox loaded 🎉`);
    // The precache manifest lists the names of the files that were processed by webpack and that end up in your dist folder.
    workbox.precaching.precacheAndRoute(self.__precacheManifest);

    addEventListener("message", (event) => {
        console.log("[service-worker.js] message", event.data);
        if (event.data && event.data.type === "SKIP_WAITING") {
            skipWaiting();
        }
    });

} else {
    console.log(`Boo! Workbox didn't load 😬`);
}
