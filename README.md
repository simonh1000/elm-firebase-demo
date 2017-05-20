# Xmas present picker

Register, set up your present wishes and claim what you want to buy for others.

##
```js
var config = {
  apiKey: "AI..................",
  authDomain: "xxxxxxx.firebaseapp.com",
  databaseURL: "https://xxxxxxxx.firebaseio.com",
  projectId: "xxxxxxx",
  storageBucket: "xxxxxxx.appspot.com",
  messagingSenderId: "123456"
};
firebase.initializeApp(config);
```

## Deploy to Firebase

```sh
npm run prod && firebase deploy
```

## ToDo

Add firebase rules so that first person to claim can't be overwritten
