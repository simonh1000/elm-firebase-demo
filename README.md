# Xmas present picker

An Elm experiment to use Firebase to provide a real time xmas present idea exchange between a family group. Register, set up your present wishes and claim what you want to buy for others.

## Installation

All that is needed is to add a file `/src/js/fbconfig.js` with your firebase data in as below:

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

 * Add firebase rules so that first person to claim can't be overwritten
 * Implement incoming port for a FBMsg so that e.g. an error on logging in can be shown to user
 * Delete item (with warning)
