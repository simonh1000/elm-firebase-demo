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
yarn prod && firebase deploy --only hosting
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
## Test functions locally

```
yarn localfunctions
```

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

## Data structure (for 2.0)

```
/key1
     - meta
         - name
     - presents
         - key2
             - description
             - ?link
             - ?takenBy : key1
             - ?purchased : Bool
```

### Normal start up

Elm starts running             Loading            Calls ListenAuthState

Authstate sends back
"authstate" and user object
 - if user                     Picker             subscribe "/"

 Snapshot


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
