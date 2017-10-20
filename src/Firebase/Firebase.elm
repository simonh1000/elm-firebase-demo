port module Firebase.Firebase exposing (..)

import Json.Encode as E
import Json.Decode as Json exposing (..)


type alias FBMsg =
    { message : String
    , payload : Value
    }


port elmToFb : FBMsg -> Cmd msg


port fbToElm : (FBMsg -> msg) -> Sub msg



-- Subscriptions


subscriptions : (FBMsg -> msg) -> Sub msg
subscriptions fbMsgHandler =
    fbToElm fbMsgHandler



--


requestMessagingPermission : Cmd msg
requestMessagingPermission =
    elmToFb <| FBMsg "RequestMessagingPermission" E.null



-- AUTHENTICATION


setUpAuthListener =
    elmToFb <| FBMsg "ListenAuthState" E.null


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
    oneOf
        [ map Ok userDecoder
        , null (Err "nouser")
        ]


userDecoder : Decoder FBUser
userDecoder =
    map4 FBUser
        (field "email" string)
        (field "uid" string)
        (maybe <| field "displayName" string)
        (maybe <| field "photoURL" string)


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


remove : String -> Cmd msg
remove ref =
    elmToFb <| FBMsg "remove" (E.string ref)
