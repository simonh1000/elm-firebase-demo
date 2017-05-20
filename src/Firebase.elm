port module Firebase exposing (..)

import Json.Encode as E exposing (..)


type alias FBMsg =
    { message : String
    , payload : Value
    }


port jsmessage : FBMsg -> Cmd msg


port authStateChange : (Value -> msg) -> Sub msg


port onSnapshot : (Value -> msg) -> Sub msg


encodeCredentials email password =
    object
        [ ( "email", string email )
        , ( "password", string password )
        ]


signin : String -> String -> Cmd msg
signin email password =
    jsmessage <| FBMsg "signin" (encodeCredentials email password)


signout =
    jsmessage <| FBMsg "signout" null


register : String -> String -> Cmd msg
register email password =
    jsmessage <| FBMsg "register" (encodeCredentials email password)


subscribe ref =
    jsmessage <| FBMsg "subscribe" <| string ref


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
