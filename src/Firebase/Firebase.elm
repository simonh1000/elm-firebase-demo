port module Firebase.Firebase exposing (..)

import Common.CoreHelpers exposing (exactMatchString)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as E
import Result.Extra as RE


type alias PortMsg =
    { message : String, payload : Value }


port elmToFb : PortMsg -> Cmd msg


port fbToElm : (Value -> msg) -> Sub msg



-- ----------------------------------------------
-- Subscriptions
-- ----------------------------------------------


type FBResponse
    = AuthState (Result String FBUser)
    | Snapshot Value -- this library does not know the structure of your data
    | MessagingToken String
    | CFError String -- ??
    | Error String
      --    | SubscriptionOk
      --    | UnsubscribeOk
      --    | NoUserPermission -- user has blocked use
      --    | NewMessage -- from the subscribed service
    | UnhandledResponse String


type alias FBMsg =
    { message : String
    , payload : Value
    }


subscriptions : (FBResponse -> msg) -> Sub msg
subscriptions msgConstructor =
    fbToElm (decodeIncoming msgConstructor)


decodeIncoming : (FBResponse -> msg) -> Value -> msg
decodeIncoming msgConstructor value =
    Decode.decodeValue fbResponseDecoder value
        |> Result.map msgConstructor
        |> RE.extract (Decode.errorToString >> Error >> msgConstructor)


fbResponseDecoder : Decoder FBResponse
fbResponseDecoder =
    let
        mkDec tgt dec constructor =
            exactMatchString (Decode.field "message" Decode.string) tgt (Decode.field "payload" dec)
                |> Decode.map constructor
    in
    Decode.oneOf
        [ mkDec "authstate" decodeAuthState AuthState
        , mkDec "snapshot" Decode.value Snapshot
        , mkDec "MessagingToken" Decode.string MessagingToken
        , mkDec "CFError" decoderError CFError
        , mkDec "Error" decoderError Error

        --        , mkDec "SubscriptionOk" (Decode.succeed ()) (\_ -> SubscriptionOk)
        , Decode.field "message" Decode.string |> Decode.map UnhandledResponse
        ]


decoderError : Decoder String
decoderError =
    Decode.field "message" Decode.string



-- Outgoing messages


type FBCommand
    = GetMessagingToken -- request firebase.messaging to provide its messaging token
    | StartNotifications String
    | StopNotifications String
    | ListenAuthState


sendToFirebase : FBCommand -> Cmd msg
sendToFirebase cmd =
    case cmd of
        StartNotifications userId ->
            elmToFb <| { message = fbCommandToString cmd, payload = E.string userId }

        StopNotifications userId ->
            elmToFb <| { message = fbCommandToString cmd, payload = E.string userId }

        _ ->
            elmToFb <| { message = fbCommandToString cmd, payload = E.null }


fbCommandToString : FBCommand -> String
fbCommandToString cmd =
    case cmd of
        GetMessagingToken ->
            "GetMessagingToken"

        StartNotifications _ ->
            "StartNotifications"

        StopNotifications _ ->
            "StopNotifications"

        ListenAuthState ->
            "ListenAuthState"



-- AUTHENTICATION


setUpAuthListener : Cmd msg
setUpAuthListener =
    sendToFirebase ListenAuthState


type alias FBUser =
    { email : String
    , uid : String
    , displayName : Maybe String
    , photoURL : Maybe String
    }


init : FBUser
init =
    { email = ""
    , uid = ""
    , displayName = Nothing
    , photoURL = Nothing
    }


decodeAuthState : Decoder (Result String FBUser)
decodeAuthState =
    Decode.oneOf
        [ Decode.map Ok userDecoder
        , Decode.null (Err "nouser")
        ]


userDecoder : Decoder FBUser
userDecoder =
    Decode.map4 FBUser
        (Decode.field "email" Decode.string)
        (Decode.field "uid" Decode.string)
        (Decode.maybe <| Decode.field "displayName" Decode.string)
        (Decode.maybe <| Decode.field "photoURL" Decode.string)


encodeCredentials : String -> String -> Value
encodeCredentials email password =
    E.object
        [ ( "email", E.string email )
        , ( "password", E.string password )
        ]


signin : String -> String -> Cmd msg
signin email password =
    elmToFb <| FBMsg "signin" (encodeCredentials email password)


signinGoogle : Cmd msg
signinGoogle =
    elmToFb <| FBMsg "signinGoogle" E.null


signout : Cmd msg
signout =
    elmToFb <| FBMsg "signout" E.null


register : String -> String -> Cmd msg
register email password =
    elmToFb <| FBMsg "register" (encodeCredentials email password)



-- DATABASE


subscribe : String -> Cmd msg
subscribe ref =
    elmToFb <| FBMsg "subscribe" <| E.string ref


push : String -> E.Value -> Cmd msg
push ref val =
    [ ( "ref", E.string ref )
    , ( "payload", val )
    ]
        |> E.object
        |> FBMsg "push"
        |> elmToFb


set : String -> E.Value -> Cmd msg
set ref val =
    [ ( "ref", E.string ref )
    , ( "payload", val )
    ]
        |> E.object
        |> FBMsg "set"
        |> elmToFb


{-| updates key values at the ref, but does not replace completely
-}
update : String -> E.Value -> Cmd msg
update ref val =
    [ ( "ref", E.string ref )
    , ( "payload", val )
    ]
        |> E.object
        |> FBMsg "update"
        |> elmToFb


remove : String -> Cmd msg
remove ref =
    elmToFb <| FBMsg "remove" (E.string ref)
