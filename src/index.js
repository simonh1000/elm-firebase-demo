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
    switch ( message) {
        case "signin":
            fb.signin(payload.email, payload.password);
            break;
        case "register":
            fb.register(payload.email, payload.password);
            break;
        case "signout":
            fb.signout();
            break;
        case "subscribe":
            fb.subscribe(app.ports.onSnapshot.send, payload);
            break;
        case "set":
            fb.set(payload);
            break;
        case "remove":
            fb.remove(payload);
            break;
        case "push":
            fb.push(payload);
            break;
        default:
            break;
    }
});
