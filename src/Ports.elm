port module Ports exposing (..)

import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode


port toJs : TaggedPayload -> Cmd msg


port fromJs : (TaggedPayload -> msg) -> Sub msg


type alias TaggedPayload =
    { tag : String
    , payload : Value
    }



-- Outgoing messages


type PortMsg
    = LogError String
    | LogRollbar Value
    | SkipWaiting


sendToJs : PortMsg -> Cmd msg
sendToJs portMsg =
    case portMsg of
        LogError str ->
            toJs <| TaggedPayload "LogError" <| Encode.string str

        LogRollbar val ->
            toJs <| TaggedPayload "LogRollbar" val

        SkipWaiting ->
            toJs <| TaggedPayload "SkipWaiting" Encode.null


rollbar : String -> Cmd msg
rollbar =
    sendToJs << LogRollbar << Encode.string



-- Incoming messages


type IncomingMsg
    = NewCode Bool
    | UnrecognisedPortMsg TaggedPayload


decodeIncomingMsg : TaggedPayload -> IncomingMsg
decodeIncomingMsg msg =
    case msg.tag of
        "NewCode" ->
            msg.payload
                |> Decode.decodeValue (Decode.map NewCode Decode.bool)
                |> Result.withDefault (UnrecognisedPortMsg msg)

        _ ->
            UnrecognisedPortMsg msg
