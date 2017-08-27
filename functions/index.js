var functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

exports.sendNotification = functions.database.ref('/{userId}/presents/{presentId}')
    .onWrite(event => {
        // Don't show any notifications before ....
        let endPhase1 = new Date("1 oct 2017");
        let now = new Date();
        // if (now < endPhase1) {
        //     returns;
        // }

        // Grab the current value of what was written to the Realtime Database.
        let present = event.data.child("description").val();

        // Stop if this is an update to exisiting data
        if (event.data.previous.exists()) {
            return;
        }

        return event.data.ref.parent.parent.child('meta/name').once("value")
            .then(snapshot => {
                var topic = "presents";
                // console.log(`* ${person} added ${present}`);
                var payload = {
                    data: {
                        person: snapshot.val(),
                        present: present
                    }
                };

                return admin.messaging().sendToTopic(topic, payload);
            })
            .then(function(response) {
                // Send a message to devices subscribed to the provided topic.
                // console.log("Successfully sent message:", response);
            })
            .catch(function(error) {
                console.error("Error sending message:", error);
            });
    });
