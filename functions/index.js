const functions = require("firebase-functions");
const admin = require("firebase-admin");

const phase2 = new Date("1 nov 2020");
const customNotificationPassword = "3D#9gxF@";

admin.initializeApp();

// notification registration handlers
const messaging = require("./messaging");
exports.subscribe = functions.https.onRequest(messaging.subscribe);
exports.unsubscribe = functions.https.onRequest(messaging.unsubscribe);
exports.customNotification = functions.https.onRequest(customNotification);

// Database watcher
// When new present created, inform users
// Changes to suggestions are not notified
exports.sendNotification = functions.database
    .ref("/{userId}/presents/{presentId}")
    .onCreate((event) => {
        // https://firebase.google.com/docs/reference/admin/node/admin.database.Reference
        return event.ref.parent.parent
            .child("meta/name")
            .once("value")
            .then((snapshot) => {
                // Grab the current value of what was written to the Realtime Database.
                let person = snapshot.val();

                // Don't provide present details before ....
                let now = new Date();
                let eventData = event.val();
                // console.log(eventData);
                // cannot return a null here
                let present = now < phase2 ? "" : eventData["description"];

                let payload = {
                    data: { person, present },
                };

                // https://firebase.google.com/docs/cloud-messaging/admin/send-messages#send_to_a_topic
                return admin.messaging().sendToTopic(messaging.topic, payload);
            })
            .catch((error) => console.error("Error sending message:", error));
    });

// http endpoint to send custom notifications
function customNotification(req, res) {
    const password = req.body.password;
    const notification = req.body.notification;
    let payload = {
        data: { notification },
    };

    if (password === customNotificationPassword) {
        return admin
            .messaging()
            .sendToTopic(messaging.topic, payload)
            .then(() => {
                res.sendStatus(200);
            })
            .catch((err) => {
                res.status(500).send({
                    error: "customNotification",
                    message: err,
                });
            });
    } else {
        return res.status(500).send({
            error: "customNotification",
            message: "bad password",
        });
    }
}
