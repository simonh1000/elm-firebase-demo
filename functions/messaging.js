//  https://us-central1-hampton-xmas.cloudfunctions.net/subscribe?token=abc123

const rp = require("request-promise");
const cors = require("cors")({ origin: true });

const secrets = require('./secrets');

exports.subscribe = function(req, res) {
    // https://firebase.google.com/docs/functions/http-events
    cors(req, res, () => {
        // console.log("messaging-registration");

        let token = req.query.token;
        let topic = "presents";
        let uri = `https://iid.googleapis.com/iid/v1/${token}/rel/topics/${topic}`;

        // Make the request to Google IID
        var myHeaders = {
            "Content-Type": "application/json",
            Authorization: "key=" + secrets.devKey
        };
        var options = {
            uri: uri,
            method: "POST",
            headers: myHeaders,
            mode: "no-cors",
            cache: "default"
        };

        rp(options)
            .then(function(response) {
                // console.log("rp success", response);
                res.status(200).send({
                    msg: "Ok from Simon for " + token,
                    payload: response}
                );
            })
            .catch(function(err) {
                console.log("[fbm.registerForUpdates] Error registering for topic", err.message);
                res.status(500).send(err);
            });
    });
};

exports.unsubscribe = function(req, res) {
    console.log("unsubscribe");
    res.sendStatus(200);
};
