"use strict";

require("./index.html");
require("bootstrap-loader");
require("./styles.scss");
require("./js/fbconfig");
import fb from './js/fb';

var Elm = require("./Main");
var app = Elm.Main.fullscreen();

// Subscribe to auth state changes
fb.createAuthListener(app.ports.authStateChange.send);

app.ports.jsmessage.subscribe( ({message, payload}) => {
    // console.log("jsmessage",message, payload);
    // Provide call back for data subscriptions
    fb.handler({message, payload}, app.ports.onSnapshot.send, app.ports.fbToElm.send);
});
