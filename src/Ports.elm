port module Ports exposing (..)

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode


port toJs : TaggedPayload -> Cmd msg


type alias TaggedPayload =
    { tag : String
    , payload : Value
    }


type PortMsg
    = LogError String
    | LogRollbar String


sendToJs : PortMsg -> Cmd msg
sendToJs portMsg =
    case portMsg of
        LogError str ->
            toJs <| TaggedPayload "LogError" <| Encode.string str

        LogRollbar str ->
            toJs <| TaggedPayload "LogRollbar" <| Encode.string str


rollbar : String -> Cmd msg
rollbar =
    sendToJs << LogRollbar
