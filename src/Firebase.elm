module Firebase exposing (..)

import Json.Encode as E exposing (..)
import Ports exposing (..)


encodeCredentials email password =
    object
        [ ( "email", string email )
        , ( "password", string password )
        ]


signin : String -> String -> Cmd msg
signin email password =
    jsmessage <| PortMsg "signin" (encodeCredentials email password)


register : String -> String -> Cmd msg
register email password =
    jsmessage <| PortMsg "register" (encodeCredentials email password)


setMeta uid name =
    [ ( "ref", string (uid ++ "/meta") )
    , ( "payload", object [ ( "name", E.string name ) ] )
    ]
        |> E.object
        |> set


simpleMsg msg =
    jsmessage <| PortMsg msg null


subscribe ref =
    jsmessage <| PortMsg "subscribe" <| string ref


push obj =
    jsmessage <| PortMsg "push" obj


set obj =
    jsmessage <| PortMsg "set" obj


remove : String -> Cmd msg
remove ref =
    jsmessage <| PortMsg "remove" (E.string ref)


makeClaimRef uid otherRef presentRef =
    object
        [ ( "ref", string <| makeTakenByRef otherRef presentRef )
        , ( "payload", string uid )
        ]


makeTakenByRef otherRef presentRef =
    otherRef ++ "/presents/" ++ presentRef ++ "/takenBy"


makePresent ref description =
    [ ( "ref", string ref )
    , ( "payload", object [ ( "description", E.string description ) ] )
    ]
        |> E.object
