# PWA featuring Firebase database & messaging with Elm frontend

An Elm experiment to use Firebase to provide a real time Xmas present idea exchange between a family group. Register, set up your present wishes and claim what you want to buy for others.

## Installation

You need to provide 3 files

###`/src/assets/config/firebase-config.js`

```js
export var firebaseConfig = {
  apiKey: ",
  authDomain: "",
  databaseURL: "",
  projectId: "",
  storageBucket: "",
  messagingSenderId: "",
  appId: ""
};
```

### src/Firebase/fbsw.config.js

```
var prod = {
  messagingSenderId: "12345",
  url: "https://xxxxxxx.firebaseapp.com/"
};
self.config = self.config || dev;
```

.... and connect the cloud functions code to the admin sdk, following https://firebase.google.com/docs/admin/setup

### .firebaserc

```
{
  "projects": {
    "default": "<project-name>>"
  }
}
```

## Set up auth

Go to auth section of firebase console

-   enable google
-   enable email + password

## Create a list of eligible email addresses

these need to convert `@` and `.` into `_`

## Deploy to Firebase: firebase-tools

Check the following are pointing to production assets:

-   functions/index.js
-   src/Firebase/fb.config.js
-   src/Firebase/fbsw.config.js
-   database.rules.json

`firebase use default`

-   Update assets/manifest.json
-   Update package.json

```
npm run prod && firebase deploy --only hosting
```

## Test functions locally

## ngrok

ngrok http 3000 -host-header="localhost:3000"

## Changelog

-   2.0.0: 2019 re-write

## ToDo

-   InScreen notification
-   remove duplicative userMessage
-   Make rollbar work only on production
-   Delete item (with warning)
-   Add firebase rules so that first person to claim can't be overwritten
