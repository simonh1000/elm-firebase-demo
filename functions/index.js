var functions = require('firebase-functions');

const admin = require('firebase-admin');
admin.initializeApp(functions.config().firebase);

var api_key = 'key-994d00ac2aa451e83688bb244d83d808';
var domain = 'sandboxd720500c186b4899a98b012288a293ce.mailgun.org';
var mailgun = require('mailgun-js')({apiKey: api_key, domain: domain});

function makeMailgun({person, present}) {
    return {
        from: 'Xmas organiser <xmas@samples.mailgun.org>',
        to: 'simhampton@gmail.com',
        subject: '[xmas]',
        text: `${person} suggested: ${present}`
    };
}

exports.sendNotification = functions.database.ref('/{userId}/presents/{presentId}')
    .onWrite(event => {
        // Don't show any notifications before ....
        let showAfter = new Date("1 sept 2017");
        let now = new Date();
        // if (now < showAfter) {
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
                let mg = makeMailgun(payload.data);
                mailgun.messages().send(mg, function (error, body) {
                    if (error) console.error(error);
                });

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
