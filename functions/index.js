const functions = require("firebase-functions");
const admin = require("firebase-admin");

const databaseURL = "https://hampton-xmas2019.firebaseio.com";
const endPhase1 = new Date("1 nov 2019");

// initialising may help with using the local emulators?
admin.initializeApp({
    credential: admin.credential.applicationDefault(),
    databaseURL
});

// notification registration handlers
const messaging = require("./messaging");
exports.subscribe = functions.https.onRequest(messaging.subscribe);
exports.unsubscribe = functions.https.onRequest(messaging.unsubscribe);

// Database watcher
// When new present created, inform users
exports.sendNotification = functions.database
    .ref("/{userId}/presents/{presentId}")
    .onCreate(event => {
        // https://firebase.google.com/docs/reference/admin/node/admin.database.Reference
        return event.ref.parent.parent
            .child("meta/name")
            .once("value")
            .then(snapshot => {
                // Grab the current value of what was written to the Realtime Database.
                let person = snapshot.val();

                // Don't provide presnet details before ....
                let now = new Date();
                // cannot return a null here
                let present =
                    now < endPhase1
                        ? ""
                        : event.data.child("description").val();

                var payload = {
                    data: { person, present }
                };

                // https://firebase.google.com/docs/cloud-messaging/admin/send-messages#send_to_a_topic
                return admin.messaging().sendToTopic(messaging.topic, payload);
            })
            .catch(error => console.error("Error sending message:", error));
    });

//// When present added to database, inform users
//exports.sendNotification =
//    functions.firestore
//    .document("/{userId}/presents/{presentId}")
//    .onWrite(event => {
//        // Stop if this is an update to existing data
//        if (event.data.previous.exists()) {
//            return;
//        }
//
//        return event.data.ref.parent.parent
//            .child("meta/name")
//            .once("value")
//            .then(snapshot => {
//                // Grab the current value of what was written to the Realtime Database.
//                let person = snapshot.val();
//
//                // Don't show any notifications before ....
//                let endPhase1 = new Date("15 oct 2017");
//                let now = new Date();
//                let present;
//                if (now < endPhase1) {
//                    present = person + " <visible October 15>";
//                } else {
//                    present = event.data.child("description").val();
//                }
//
//                var topic = "presents";
//                // console.log(`* ${person} added ${present}`);
//                var payload = {
//                    data: { person, present }
//                };
//
//                // https://firebase.google.com/docs/cloud-messaging/admin/send-messages#send_to_a_topic
//                return admin.messaging().sendToTopic(topic, payload);
//            })
//            .then( response => {
//                console.log("Message(s) sent", response);
//            })
//            .catch(error => console.error("Error sending message:", error));
//    });
