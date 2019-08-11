# PWA featuring Firebase messaging and data base with Elm frontend

An Elm experiment to use Firebase to provide a real time xmas present idea exchange between a family group. Register, set up your present wishes and claim what you want to buy for others.

## Deploy to Firebase: firebase-tools

Check the following are pointing to production assets:

 - functions/index.js
 - src/Firebase/fb.config.js
 - src/Firebase/fbsw.config.js
 - database.rules.json 
 
 `firebase use default`

 - Update assets/mainfest.json
 - Update package.json

```
npm run prod && firebase deploy --only hosting
```

## Installation

Add you config to `/src/assets/firebase-init.js`

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

### Set up auth 
Go to auth section of firebase console

- enable google
- enable email + password 


## Test functions locally

firebase serve --only functions,database

https://firebase.google.com/docs/functions/local-emulator
firebase emulators:start


```
firebase setup:emulators:database

npm run localfunctions
```

- start the database so that you can test rules `firebase serve --only database`
- Get some sort of command line to access the functions: `npm run shell`


## src/Firebase/fbsw.config.js
```
var prod = {
  messagingSenderId: "58123453",
  url: "https://xxxxxxx.firebaseapp.com/"
};
self.config = self.config || dev;
```

.... and connect the cloud functions code to the admin sdk, following https://firebase.google.com/docs/admin/setup

## Changelog

 - 2.1.0:


## ToDo

 * Generate sw.js directly in ./dist
 * Delete item (with warning)
 * add click-action to notification
 * Add firebase rules so that first person to claim can't be overwritten
