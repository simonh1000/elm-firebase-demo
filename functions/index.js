var functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.helloWorld = functions.https.onRequest((request, response) => {
 response.send("Hello from Firebase!");
});

// exports.sendNotification = functions.database.ref('/{userId}')
//     .onWrite(event => {
//
//         // Grab the current value of what was written to the Realtime Database.
//         var eventSnapshot = event.data;
//         var str1 = "Author is ";
//         var str = str1.concat(eventSnapshot.child("author").val());
//         console.log(str);
//
//         var topic = "android";
//         var payload = {
//             data: {
//                 title: eventSnapshot.child("title").val(),
//                 author: eventSnapshot.child("author").val()
//             }
//         };
//
//         // Send a message to devices subscribed to the provided topic.
//         return admin.messaging().sendToTopic(topic, payload)
//             .then(function(response) {
//                 // See the MessagingTopicResponse reference documentation for the
//                 // contents of response.
//                 console.log("Successfully sent message:", response);
//             })
//             .catch(function(error) {
//                 console.log("Error sending message:", error);
//             });
//     });
