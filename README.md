# PWA featuring Firebase messaging and data base with Elm frontend

An Elm experiment to use Firebase to provide a real time xmas present idea exchange between a family group. Register, set up your present wishes and claim what you want to buy for others.

## Installation

All that is needed is to add two files

`/src/Firebase/fb.config.js`

```js
var config = {
  apiKey: "AI..................",
  authDomain: "xxxxxxx.firebaseapp.com",
  databaseURL: "https://xxxxxxxx.firebaseio.com",
  projectId: "xxxxxxx",
  storageBucket: "xxxxxxx.appspot.com",
  messagingSenderId: "123456"
};
export default config;
```

`/src/Firebase/fbsw.config.js`

```js
var config = {
  messagingSenderId: "123456"
};
self.config = self.config || config;
```

## Deploy to Firebase

```sh
npm run build && firebase deploy --only hosting
```

## ToDo

 * Delete item (with warning)
 * add click-action to notification
 * Add firebase rules so that first person to claim can't be overwritten
