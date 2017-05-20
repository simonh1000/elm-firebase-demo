module Main exposing (main)

import Html
import Firebase
import App exposing (..)


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }


subscriptions model =
    Sub.batch
        [ Firebase.authStateChange OnAuthStateChange
        , Firebase.onSnapshot OnSnapshot
        ]
