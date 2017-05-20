module Main exposing (main)

import Html
import Ports
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
        [ Ports.authStateChange OnAuthStateChange
        , Ports.onSnapshot OnSnapshot
        ]
