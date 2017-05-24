function requestMessagingPermission() {
    const messaging = firebase.messaging();
    messaging.requestPermission()
        .then(function() {
            console.log('Notification permission granted.');
            // TODO(developer): Retrieve an Instance ID token for use with FCM.
            return getToken();
            // ...
        })
        .catch(function(err) {
            console.log('Unable to get permission to notify.', err);
        });

    // Handle incoming messages. Called when:
    // - a message is received while the app has focus
    // - the user clicks on an app notification created by a sevice worker
    //   `messaging.setBackgroundMessageHandler` handler.
    messaging.onMessage(function(payload) {
      console.log("Message received. ", payload);
      // ...
    });
    //
    // messaging.setBackgroundMessageHandler(function(payload) {
    //     console.log('[firebase-messaging-sw.js] Received background message ', payload);
    //     // Customize notification here
    //     const notificationTitle = 'Background Message Title';
    //     const notificationOptions = {
    //         body: 'Background Message body.',
    //         icon: '/firebase-logo.png'
    //     };
    //
    //     return self.registration.showNotification(notificationTitle,
    //         notificationOptions);
    // });

}

function getToken() {
    const messaging = firebase.messaging();

    // Get Instance ID token. Initially this makes a network call, once retrieved
    // subsequent calls to getToken will return from cache.
    return messaging.getToken()
        .then(function(currentToken) {
            if (currentToken) {
                // Register for topic: presents
                let topic = "presents"
                let url = `https://iid.googleapis.com/iid/v1/${currentToken}/rel/topics/${topic}`;
                // console.log(url);
                var myHeaders = new Headers();
                myHeaders.append("Content-Type", "application/json");
                myHeaders.append("Authorization", "key=AAAAvDlB7Io:APA91bG00Uie2BS5TpkCwQPTqoiAOqo0Nbzo0hEfZfs5R_0iTPRyvmvXl0NIzwjvZsbYbYFMihauJeLZQoSHJEJHyYm75Wj5XvKoIKDYkSISjm9qcM_LohrQDsWCVMdx9rXl9L2QxXpD");
                var myInit = {
                    method: 'POST',
                    headers: myHeaders,
                    mode: 'cors',
                    cache: 'default',
               };
               var myRequest = new Request(url, myInit);
               fetch(myRequest)
                   .then(function(response) {
                       if (response.status !== 200)
                        console.eror("Bad response",response);
                   })
                   .catch( (err) => {
                       console.error("error registering for topic", err)
                   });
            } else {
                // Show permission request.
                console.log('No Instance ID token available. Request permission to generate one.');
                // Show permission UI.
                // updateUIForPushPermissionRequired();
                // setTokenSentToServer(false);
            }
        })
        .catch(function(err) {
            console.error('An error occurred while retrieving token. ', err);
            // showToken('Error retrieving Instance ID token. ', err);
            // setTokenSentToServer(false);
        });
}

export default {
    requestMessagingPermission
};
