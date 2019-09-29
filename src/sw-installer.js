// Installs the service worker
// Check that service workers are supported
if ("serviceWorker" in navigator) {
    // Use the window load event to keep the page load performant
    window.addEventListener("load", () => {
        navigator.serviceWorker.register("/service-worker.js");
    });
}

// Why is it not in assets?
//if ("serviceWorker" in navigator) {
//    window.addEventListener("load", function() {
//        navigator.serviceWorker.register("/sw.js").then(
//            // navigator.serviceWorker.register("/firebase-messaging-sw.js").then(
//            function(registration) {
//                // Registration was successful
//                console.log(
//                    "[sw-installer] ServiceWorker registration successful with scope: ",
//                    registration.scope
//                );
//            },
//            function(err) {
//                // registration failed :(
//                console.log(
//                    "[sw-installer] ServiceWorker registration failed: ",
//                    err
//                );
//            }
//        );
//    });
//}
