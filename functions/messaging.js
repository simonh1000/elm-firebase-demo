//  https://us-central1-hampton-xmas.cloudfunctions.net/subscribe?token=abc123

const rp = require("request-promise");

// Load firebase admin
const admin = require("firebase-admin");

const secrets = require('./secrets');

exports.subscribe = function subscribe(req, res) {
    // https://firebase.google.com/docs/functions/http-events
    const cors = require("cors")({ origin: true });
    cors(req, res, () => {
        console.log("messaging-registration");

        // Because the Content-Type was to set to json we do not need manually to parse
        let body = req.body;
        var token = body.token;
        var userId = body.userId;
        console.log("token", token);
        console.log("userId", userId);

        admin.database().ref(userId + "/meta/")
            .update({"token": token})
            .then(response => {
                console.log("rp success", response);
                res.status(200).send({
                    message: "CloudFunctionOk",
                    payload: response
                });
            })
            .catch(err => {
                console.log("[fbm.registerForUpdates] Error registering for topic", err.message);
                res.status(500).send(err);
            });
    });
};

exports.unsubscribe = function(req, res) {
    console.log("unsubscribe");
    res.sendStatus(200);
};


// let topic = "presents";
// let uri = `https://iid.googleapis.com/iid/v1/${token}/rel/topics/${topic}`;
//
// // Make the request to Google IID
// var myHeaders = {
//     "Content-Type": "application/json",
//     Authorization: "key=" + secrets.prodKey
// };
// var options = {
//     uri: uri,
//     method: "POST",
//     headers: myHeaders,
//     mode: "no-cors",
//     cache: "default"
// };
//
// rp(options)
//     .then(function(response) {
//         // console.log("rp success", response);
//         res.status(200).send({
//             msg: "Ok from Simon for " + token,
//             payload: response}
//         );
//     })
//     .catch(function(err) {
//         console.log("[fbm.registerForUpdates] Error registering for topic", err.message);
//         res.status(500).send(err);
//     });
