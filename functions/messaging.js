// Load firebase admin
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });
var topic = "presents";


exports.subscribe = function subscribe(req, res) {
    // https://firebase.google.com/docs/functions/http-events
    cors(req, res, () => {
        // Because the Content-Type was to set to json we do not need manually to parse
        var token = req.body.token;
        // https://firebase.google.com/docs/cloud-messaging/admin/manage-topic-subscriptions
        admin.messaging().subscribeToTopic(token, topic)
            .then(response => {
                // https://firebase.google.com/docs/reference/admin/node/admin.messaging.MessagingTopicManagementResponse
                res.status(200).send({
                    message: "SubscriptionOk",
                    payload: topic
                });
            })
            .catch(err => {
                console.log("[fbm.registerForUpdates] Error registering for topic", err.message);
                res.status(500).send({
                    message: "CFError",
                    payload: err
                });
            });
    });
};

exports.unsubscribe = function(req, res) {
    var token = req.body.token;
    console.log("unsubscribe starting", token);
    // https://firebase.google.com/docs/cloud-messaging/admin/manage-topic-subscriptions
    cors(req, res, () => {
        admin.messaging().unsubscribeFromTopic(token, topic)
            .then(response => {
                // https://firebase.google.com/docs/reference/admin/node/admin.messaging.MessagingTopicManagementResponse
                console.log("UnsubscribeOk", response);
                res.status(200).send({
                    message: "UnsubscribeOk",
                    payload: topic
                });
            })
            .catch(err => {
                console.log("[fbm.registerForUpdates] Error registering for topic", err.message);
                res.status(500).send({
                    message: "CFError",
                    payload: err
                });
            });
    });
};
