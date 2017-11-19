# PWA featuring Firebase messaging and data base with Elm frontend

An Elm experiment to use Firebase to provide a real time xmas present idea exchange between a family group. Register, set up your present wishes and claim what you want to buy for others.

## Deploy to Firebase: firebase-tools


No update of functions
**!! assets/mainfest.json / package.json - bump !!**
```sh
**!! assets/mainfest.json/package.json - bump !!**
npm run prod && firebase deploy --only hosting
```

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
https://console.firebase.google.com/project/\<projid\>/settings/cloudmessaging/

```js
var config = {
  messagingSenderId: "123456"
};
self.config = self.config || config;
```

## ToDo

 * Generate sw.js directly in ./dist
 * Delete item (with warning)
 * add click-action to notification
 * Add firebase rules so that first person to claim can't be overwritten


### Signup flow

Google
    - auth returns a username, sends a snapshot without username
    - so send username when auth returns?  (or when discover snapshot does not contain own username)

Email registration
    - app collects username, but does not initially send it anywhere
    - auth returns no username, know that username needs to be saved

On subsequent signup

Google
    - auth returns a username, sends a snapshot WITH username
Email
    - auth return NO username
