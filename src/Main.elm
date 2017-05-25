module Main exposing (main)

import Html
import Firebase.Firebase as FB
import App exposing (..)


main =
    Html.program
        { init = init
        , update = update
        , view = view
        , subscriptions =
            FB.subscriptions FBMsgHandler
        }
