"use strict";

require("./index.html");
require("bootstrap-loader");
require("./styles.scss");

var Elm = require("./Main");
var app = Elm.Main.fullscreen();

// Set up Firebase and main handler
import config from "./Firebase/fb.config";
firebase.initializeApp(config);
import fb from './Firebase/fb';
app.ports.elmToFb.subscribe( msg => fb.handler(msg, app.ports.fbToElm.send) );
