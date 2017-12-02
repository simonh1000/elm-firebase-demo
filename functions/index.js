var functions = require("firebase-functions");

const admin = require("firebase-admin");
var serviceAccount = require("./xmas-f3f6b-adminsdk.json");
//
// admin.initializeApp(functions.config().firebase);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://xmas-f3f6b.firebaseio.com"
});

const messaging = require("./messaging");

// Subscribe to messaging
exports.subscribe = functions.https.onRequest(messaging.subscribe);

// When present added to database, inform users
exports.sendNotification = functions.database.ref("/{userId}/presents/{presentId}").onWrite(event => {
    // Stop if this is an update to exisiting data
    if (event.data.previous.exists()) {
        return;
    }

    return event.data.ref.parent.parent
        .child("meta/name")
        .once("value")
        .then(snapshot => {
            // Grab the current value of what was written to the Realtime Database.
            let person = snapshot.val();

            // Don't show any notifications before ....
            let endPhase1 = new Date("15 oct 2017");
            let now = new Date();
            let present;
            if (now < endPhase1) {
                present = person + " <visible October 15>";
            } else {
                present = event.data.child("description").val();
            }

            var topic = "presents";
            // console.log(`* ${person} added ${present}`);
            var payload = {
                data: { person, present }
            };

            return admin.messaging().sendToTopic(topic, payload);
        })
        .catch(error => console.error("Error sending message:", error));
});
