# 2018

 - initial registration requires a code to join an existing group
 - option to add ideas you have for someone else

## Registration flow

 - pick a groupID
    - check whether it exists: either
        - show the Group name; or
            - if accept, then show form for user registration
        - offer the user chance to create new group
            - form for Group name
            - form for user registration
            - On submit
                - create group, returning GroupID
                - add groupId to User registration credentials

# Start-up of app

signed in
    - App.init
        - request messaging permission
        - start auth state subscription


## Database

- groups
    - group name
        - group secret
        - groupID
- groupID
    - users
        - userId
            - name
            - notifications
            - ideas    -- want to prevent this data being served to all users
                - presentId
                    - userId
                    - present
                    - link
                    - purchased?
            - claimed
                - presentId
                    - purchased?
                    - [amount]
    - presents
        - userId
            - name: "Simon Hampton"
            - presentId
                - present
                - link
                - takenById



## Functions
 - for groupIDs :
    - returns the FB key for a groupID
    - prevent users from being passed a list of all groups



# Get list of users

https://firebase.google.com/docs/cli/auth#authexport
firebase auth:export users.json --format=json

{
  "rules": {
      ".read"  : "auth != null && root.child('users').child(auth.uid).val() === true",
      ".write" : "auth != null && root.child('users').child(auth.uid).val() === true"
  }
}

<!--  Does not work because can't put a @ in the key of a data item -->
{
  "rules": {
      ".read"  : "auth != null && root.child('users').hasChild(auth.token.email),
      ".write" : "auth != null && root.child('users').hasChild(auth.token.email)
  }
}

tools/convert.json
