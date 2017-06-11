"use strict";

require('./sw-installer');
require("bootstrap-loader");
require("./styles.scss");
// require('firebase');

var Elm = require("./Main");
var app = Elm.Main.fullscreen();

// Once Elm is running, remove the existing 'app=shell'
app.ports.removeAppShell.subscribe(() => {
    document.querySelector(".removable").remove();
});

// F i r e b a s e
import config from "./Firebase/fb.config";
firebase.initializeApp(config);
// Load main firebase handler
import fb from './Firebase/fb';
// Finally, set up Elm to use Firebase handler
app.ports.elmToFb.subscribe(msg => fb.handler(msg, app.ports.fbToElm.send));
