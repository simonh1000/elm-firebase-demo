var functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

exports.sendNotification = functions.database.ref('/{userId}/presents/{presentId}')
    .onWrite(event => {
        // Stop if this is an update to exisiting data
        if (event.data.previous.exists()) {
            return;
        }

        return event.data.ref.parent.parent.child('meta/name').once("value")
            .then(snapshot => {
                // Grab the current value of what was written to the Realtime Database.
                let person = snapshot.val();

                // Don't show any notifications before ....
                let endPhase1 = new Date("1 oct 2017");
                let now = new Date();
                let present;
                if (now < endPhase1) {
                    present = person + " <visible in October>";
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
            .catch(function(error) {
                console.error("Error sending message:", error);
            });
    });
