function requestMessagingPermission(cb) {
    const messaging = firebase.messaging();
    messaging.requestPermission()
        .then(function() {
            console.log('Notification permission granted.');
            return getToken();
        })
        .catch(function(err) {
            console.log('Unable to get permission to notify.', err);
        });

    messaging.onMessage(function(payload) {
      console.log("Message received. ", payload);
      cb({
          message: "OnMessage",
          payload: payload
      })
    });
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
                        if (response.status !== 200) {
                            return console.eror("Bad response",response);
                        }

                        return console.log("Registered for topic:", topic);
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
