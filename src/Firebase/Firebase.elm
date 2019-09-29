port module Firebase.Firebase exposing (..)

import Common.CoreHelpers exposing (exactMatchString)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Result.Extra as RE


type alias PortMsg =
    { message : String
    , payload : Value
    }


port elmToFb : PortMsg -> Cmd msg


port fbToElm : (Value -> msg) -> Sub msg



-- ----------------------------------------------
-- Incoming subscriptions (via port)
-- ----------------------------------------------


subscriptions : (FBResponse -> msg) -> Sub msg
subscriptions msgConstructor =
    fbToElm (decodeIncoming msgConstructor)


type FBResponse
    = NewAuthState AuthState -- details of the user
    | Snapshot Value -- this library does not know the structure of your data
    | MessagingToken String -- the token needed to (un)subscribe for notifications
    | NotificationsRefused -- user has blocked use
    | NewNotification Notification -- will only be received if app is in 'focus'
    | Error String
    | UnhandledResponse String


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
        [ mkDec "authstate" decodeAuthState NewAuthState
        , mkDec "snapshot" Decode.value Snapshot
        , mkDec "MessagingToken" Decode.string MessagingToken
        , mkDec "Error" decoderError Error
        , mkDec "NotificationsRefused" (Decode.succeed ()) (\_ -> NotificationsRefused)
        , mkDec "NewNotification" decodeNotification NewNotification
        , Decode.field "message" Decode.string |> Decode.map UnhandledResponse
        ]


decoderError : Decoder String
decoderError =
    Decode.field "message" Decode.string



-- AuthState


type AuthState
    = AuthenticatedUser FBUser
    | NoUser


decodeAuthState : Decoder AuthState
decodeAuthState =
    Decode.oneOf
        [ Decode.map AuthenticatedUser userDecoder
        , Decode.null NoUser
        ]



-- FBUser


type alias FBUser =
    { email : String
    , uid : String
    , displayName : Maybe String
    , photoURL : Maybe String
    }


blankFBUser : FBUser
blankFBUser =
    { email = ""
    , uid = ""
    , displayName = Nothing
    , photoURL = Nothing
    }


userDecoder : Decoder FBUser
userDecoder =
    Decode.map4 FBUser
        (Decode.field "email" Decode.string)
        (Decode.field "uid" Decode.string)
        (Decode.maybe <| Decode.field "displayName" Decode.string)
        (Decode.maybe <| Decode.field "photoURL" Decode.string)



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



-- ----------------------------------------------
-- Outgoing messages
-- ----------------------------------------------


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


{-| -}
setUpAuthListener : Cmd msg
setUpAuthListener =
    sendToFirebase ListenAuthState



-- auth related


signin : String -> String -> Cmd msg
signin email password =
    elmToFb <| PortMsg "signin" (encodeCredentials email password)


signinGoogle : Cmd msg
signinGoogle =
    elmToFb <| PortMsg "signinGoogle" Encode.null


signout : Cmd msg
signout =
    elmToFb <| PortMsg "signout" Encode.null


register : String -> String -> Cmd msg
register email password =
    elmToFb <| PortMsg "register" (encodeCredentials email password)


encodeCredentials : String -> String -> Value
encodeCredentials email password =
    Encode.object
        [ ( "email", Encode.string email )
        , ( "password", Encode.string password )
        ]



-- DATABASE


subscribe : String -> Cmd msg
subscribe ref =
    elmToFb <| PortMsg "subscribe" <| Encode.string ref


push : String -> Encode.Value -> Cmd msg
push ref val =
    [ ( "ref", Encode.string ref )
    , ( "payload", val )
    ]
        |> Encode.object
        |> PortMsg "push"
        |> elmToFb


set : String -> Encode.Value -> Cmd msg
set ref val =
    [ ( "ref", Encode.string ref )
    , ( "payload", val )
    ]
        |> Encode.object
        |> PortMsg "set"
        |> elmToFb


{-| updates key values at the ref, but does not replace completely
-}
update : String -> Encode.Value -> Cmd msg
update ref val =
    [ ( "ref", Encode.string ref )
    , ( "payload", val )
    ]
        |> Encode.object
        |> PortMsg "update"
        |> elmToFb


remove : String -> Cmd msg
remove ref =
    elmToFb <| PortMsg "remove" (Encode.string ref)
