port module Ports exposing (..)

import Json.Encode exposing (Value)


type alias PortMsg =
    { message : String
    , payload : Value
    }


port jsmessage : PortMsg -> Cmd msg


port authStateChange : (Value -> msg) -> Sub msg


port onSnapshot : (Value -> msg) -> Sub msg
