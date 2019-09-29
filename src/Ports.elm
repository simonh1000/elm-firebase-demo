port module Ports exposing (..)

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode


port toJs : TaggedPayload -> Cmd msg


type alias TaggedPayload =
    { tag : String
    , payload : Value
    }


decodeFBFunction : Decoder TaggedPayload
decodeFBFunction =
    Decode.map2 TaggedPayload
        (Decode.field "message" Decode.string)
        (Decode.field "payload" Decode.value)


type PortMsg
    = LogRollbar String


sendToJs : PortMsg -> Cmd msg
sendToJs portMsg =
    case portMsg of
        LogRollbar str ->
            toJs <| TaggedPayload "LogRollbar" <| Encode.string str
