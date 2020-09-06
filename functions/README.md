# Cloud Functions

## Deploy

from root directory

```
firebase deploy --only functions
```

## Test locally

NOTE: As of Sept 2019 it is NOT possible to emulate sendNotifications because only watchers on the firestore are supported

To test the (un)subscribe functions we can follow https://firebase.google.com/docs/functions/local-emulator
```
export GOOGLE_APPLICATION_CREDENTIALS="/.../ignore/fbkey.json"
firebase emulators:start
```

## Old

```
firebase setup:emulators:database

test running:
firebase serve --only database


npm install .....
firebase emulators:start
npm run localfunctions
```

-   start the database so that you can test rules `firebase serve --only database`
