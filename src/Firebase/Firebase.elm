port module Firebase.Firebase exposing (..)

import Common.CoreHelpers exposing (exactMatchString)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
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
    | NotificationsRefused -- user has blocked use
    | NewNotification Notification -- will only be received if app is in 'focus'
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
        , mkDec "NotificationsRefused" (Decode.succeed ()) (\_ -> NotificationsRefused)
        , mkDec "NewNotification" decodeNotification NewNotification
        , Decode.field "message" Decode.string |> Decode.map UnhandledResponse
        ]


decoderError : Decoder String
decoderError =
    Decode.field "message" Decode.string



-- Notification


type alias Notification =
    { person : String
    , present : String
    }


decodeNotification : Decoder Notification
decodeNotification =
    Decode.map2 Notification
        (Decode.field "person" Decode.string)
        (Decode.field "present" Decode.string)



-- Outgoing messages


type FBCommand
    = GetMessagingToken -- request firebase.messaging to provide its messaging token
    | ListenAuthState


sendToFirebase : FBCommand -> Cmd msg
sendToFirebase cmd =
    case cmd of
        _ ->
            elmToFb <| { message = fbCommandToString cmd, payload = Encode.null }


fbCommandToString : FBCommand -> String
fbCommandToString cmd =
    case cmd of
        GetMessagingToken ->
            "GetMessagingToken"

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
    Encode.object
        [ ( "email", Encode.string email )
        , ( "password", Encode.string password )
        ]


signin : String -> String -> Cmd msg
signin email password =
    elmToFb <| FBMsg "signin" (encodeCredentials email password)


signinGoogle : Cmd msg
signinGoogle =
    elmToFb <| FBMsg "signinGoogle" Encode.null


signout : Cmd msg
signout =
    elmToFb <| FBMsg "signout" Encode.null


register : String -> String -> Cmd msg
register email password =
    elmToFb <| FBMsg "register" (encodeCredentials email password)



-- DATABASE


subscribe : String -> Cmd msg
subscribe ref =
    elmToFb <| FBMsg "subscribe" <| Encode.string ref


push : String -> Encode.Value -> Cmd msg
push ref val =
    [ ( "ref", Encode.string ref )
    , ( "payload", val )
    ]
        |> Encode.object
        |> FBMsg "push"
        |> elmToFb


set : String -> Encode.Value -> Cmd msg
set ref val =
    [ ( "ref", Encode.string ref )
    , ( "payload", val )
    ]
        |> Encode.object
        |> FBMsg "set"
        |> elmToFb


{-| updates key values at the ref, but does not replace completely
-}
update : String -> Encode.Value -> Cmd msg
update ref val =
    [ ( "ref", Encode.string ref )
    , ( "payload", val )
    ]
        |> Encode.object
        |> FBMsg "update"
        |> elmToFb


remove : String -> Cmd msg
remove ref =
    elmToFb <| FBMsg "remove" (Encode.string ref)
