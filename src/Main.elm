module Main exposing (main)

import Html
import Firebase
import App exposing (..)


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions =
            Firebase.subscriptions FBMsgHandler OnAuthStateChange OnSnapshot
        }
