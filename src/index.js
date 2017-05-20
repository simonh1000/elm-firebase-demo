"use strict";

require("./index.html");
require("bootstrap-loader");
require("./styles.scss");
require("./js/fbconfig");
import fb from './js/fb';

var Elm = require("./Main");
var app = Elm.Main.fullscreen();

fb.createAuthListener(app.ports.authStateChange.send);

app.ports.jsmessage.subscribe( ({message, payload}) => {
    console.log("jsmessage",message, payload);
    fb.handler({message, payload}, app.ports.onSnapshot.send);
});
