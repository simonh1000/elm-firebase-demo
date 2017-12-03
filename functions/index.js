const functions = require("firebase-functions");
const admin = require("firebase-admin");

const secrets = require("./secrets");
const messaging = require("./messaging");

// Set to dev / prod
var credentials = "./prod.adminsdk.json";
var dbUrl = secrets.prodUrl


var serviceAccount = require(credentials);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: dbUrl
});

// Messaging HTTP functions
exports.subscribe = functions.https.onRequest(messaging.subscribe);
exports.unsubscribe = functions.https.onRequest(messaging.unsubscribe);

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

            // https://firebase.google.com/docs/cloud-messaging/admin/send-messages#send_to_a_topic
            return admin.messaging().sendToTopic(topic, payload);
        })
        .then( response => {
            console.log("Message(s) sent", response);
        })
        .catch(error => console.error("Error sending message:", error));
});
