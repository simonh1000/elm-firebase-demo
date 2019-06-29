module Main exposing (main)

import App exposing (Msg(..), init, update, view)
import Browser
import Firebase.Firebase as FB


main =
    Browser.document
        { init = init
        , update = update
        , view = \m -> { title = "", body = [ view m ] }
        , subscriptions =
            always (FB.subscriptions FBMsgHandler)

        --        , onUrlRequest = \_ -> NoOp
        --        , onUrlChange = \_ -> NoOp
        }
