"use strict";

require("./index.html");
require("bootstrap-loader");
require("./styles.scss");
require("./Firebase/fbconfig");
import fb from './Firebase/fb';
import fbmsg from './Firebase/fbm';

var Elm = require("./Main");
var app = Elm.Main.fullscreen();

// Subscribe to auth state changes
fb.createAuthListener(app.ports.fbToElm.send);
fbmsg.requestMessagingPermission(app.ports.fbToElm.send);

app.ports.elmToFb.subscribe( ({message, payload}) => {
    // console.log("elmToFb",message, payload);
    // Provide call back for data subscriptions
    fb.handler({message, payload}, app.ports.fbToElm.send);
});
