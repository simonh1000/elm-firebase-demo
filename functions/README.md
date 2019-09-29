# Cloud Functions

## Deploy

from root directory

```
firebase deploy --only functions
```

## Test locally

NOTE: As of Sept 2019 it is not possible to emulate sendNotifications because only watchers on teh firesotre are supported

```
export GOOGLE_APPLICATION_CREDENTIALS="/Users/simonhampton/code/Elm/xmas2/ignore/fbkey.json"
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
