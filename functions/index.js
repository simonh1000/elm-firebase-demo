var functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.helloWorld = functions.https.onRequest((request, response) => {
 response.send("Hello from Firebase!");
});

exports.sendNotification = functions.database.ref('/{userId}')
    .onWrite(event => {

        // Grab the current value of what was written to the Realtime Database.
        var eventSnapshot = event.data;
        var person = eventSnapshot.child("meta").child("name").val()
        console.log("new write by", person);

        var topic = "presents";
        var payload = {
            data: {
                person: person
            }
        };

        // Send a message to devices subscribed to the provided topic.
        return admin.messaging().sendToTopic(topic, payload)
            .then(function(response) {
                // See the MessagingTopicResponse reference documentation for the
                // contents of response.
                console.log("Successfully sent message:", response);
            })
            .catch(function(error) {
                console.log("Error sending message:", error);
            });
    });
