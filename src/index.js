"use strict";

require('./sw-installer');
// require("./index.html");
require("bootstrap-loader");
require("./styles.scss");
// require('firebase');

var Elm = require("./Main");
var app = Elm.Main.fullscreen();

app.ports.removeAppShell.subscribe( () => {
    document.querySelector(".removable").remove();
});

// Set up Firebase and main handler
import config from "./Firebase/fb.config";
firebase.initializeApp(config);
// Load main firebase handler
import fb from './Firebase/fb';
// Finally, set up Elm to use Firebase handler
app.ports.elmToFb.subscribe( msg => fb.handler(msg, app.ports.fbToElm.send) );
