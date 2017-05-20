port module Firebase exposing (..)

import Json.Encode as E
import Json.Decode as Json exposing (..)


type alias FBMsg =
    { message : String
    , payload : Value
    }


port jsmessage : FBMsg -> Cmd msg


port authStateChange : (Value -> msg) -> Sub msg


port onSnapshot : (Value -> msg) -> Sub msg



-- AUTHENTICATION


type alias FBUser =
    { email : String
    , uid : String
    , displayName : Maybe String
    , photoURL : Maybe String
    }


init =
    { email = ""
    , uid = ""
    , displayName = Nothing
    , photoURL = Nothing
    }


decodeAuthState : Decoder (Result String FBUser)
decodeAuthState =
    oneOf
        [ map Err <| field "error" string
        , map Ok userDecoder
        , succeed <| Err ""
        ]


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
    jsmessage <| FBMsg "signin" (encodeCredentials email password)


signinGoogle : Cmd msg
signinGoogle =
    jsmessage <| FBMsg "signinGoogle" E.null


signout =
    jsmessage <| FBMsg "signout" E.null


register : String -> String -> Cmd msg
register email password =
    jsmessage <| FBMsg "register" (encodeCredentials email password)



-- DATABASE


subscribe ref =
    jsmessage <| FBMsg "subscribe" <| E.string ref


push : String -> E.Value -> Cmd msg
push ref val =
    [ ( "ref", E.string ref )
    , ( "payload", val )
    ]
        |> E.object
        |> FBMsg "push"
        |> jsmessage


set : String -> E.Value -> Cmd msg
set ref val =
    [ ( "ref", E.string ref )
    , ( "payload", val )
    ]
        |> E.object
        |> FBMsg "set"
        |> jsmessage


remove : String -> Cmd msg
remove ref =
    jsmessage <| FBMsg "remove" (E.string ref)
