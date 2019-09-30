// http handlers for (un)subscribing for notifications

// Load firebase admin
// use require as import not supported by firebase yet
const admin = require("firebase-admin");
const cors = require("cors")({ origin: true });

exports.topic = "presents";

exports.subscribe = function subscribe(req, res) {
    common(true, req, res);
};

exports.unsubscribe = function(req, res) {
    common(false, req, res);
};

function common(isSubscribe, req, res) {
    var messaging = admin.messaging();
    var token = req.body.token;
    const msg = isSubscribe ? "SubscriptionOk" : "UnsubscribeOk";
    console.log("common", isSubscribe, token);
    res.set("Access-Control-Allow-Origin", "*");
    // https://firebase.google.com/docs/cloud-messaging/admin/manage-topic-subscriptions
    cors(req, res, () => {
        if (isSubscribe) {
            messaging
                .subscribeToTopic(token, topic)
                .then(response => handleSuccess(msg, res, response))
                .catch(err => handleErr(res, err));
        } else {
            messaging
                .unsubscribeFromTopic(token, topic)
                .then(response => handleSuccess(msg, res, response))
                .catch(err => handleErr(res, err));
        }
    });
}

function handleSuccess(msg, res, response) {
    // https://firebase.google.com/docs/reference/admin/node/admin.messaging.MessagingTopicManagementResponse
    // console.log("UnsubscribeOk", response);
    res.status(200).send({
        message: msg,
        payload: topic
    });
}

function handleErr(res, err) {
    console.log("**", err);
    res.status(500).send({
        message: "CFError",
        payload: err
    });
}
