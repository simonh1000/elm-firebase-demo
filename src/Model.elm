module Model exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode as E
import Dict exposing (Dict)
import List as L


type Page
    = Login
    | Register
    | Picker


type alias Model =
    { page : Page
    , email : String
    , password : String
    , password2 : String
    , name : String
    , user : AuthData
    , xmas : Dict String UserData
    , userMessage : String
    , editor : Present
    }


blank : Model
blank =
    { page = Login
    , email = ""
    , password = ""
    , password2 = ""
    , name = ""
    , user = blankUser
    , xmas = Dict.empty
    , userMessage = ""
    , editor = blankPresent
    }


type alias UserData =
    { meta : UserMeta
    , presents : Dict String Present
    }


type alias Present =
    { uid : Maybe String
    , description : String
    , link : Maybe String
    , takenBy : Maybe String
    }


blankPresent =
    { uid = Nothing
    , description = ""
    , link = Nothing
    , takenBy = Nothing
    }


type alias UserMeta =
    { name : String
    }


type alias AuthData =
    { email : String
    , uid : String
    }


blankUser =
    { email = ""
    , uid = ""
    }



-- DECODER


decodeAuthState : Decoder (Result String AuthData)
decodeAuthState =
    oneOf
        [ map Err <| field "error" string
        , map Ok decodeUser
        ]


decodeUser =
    map2 AuthData
        (field "email" string)
        (field "uid" string)


decoderXmas =
    field "value" <| dict decodeUserData


decodeUserData =
    map2 UserData
        (field "meta" decoderMeta)
        (Json.oneOf [ field "presents" decodePresents, Json.succeed Dict.empty ])


decodePresents =
    let
        go ( id, p ) ps =
            case decodeValue decoderPresent p of
                Ok ( des, lnk, tk ) ->
                    Dict.insert id (Present (Just id) des lnk tk) ps

                Err err ->
                    ps
    in
        keyValuePairs value
            |> andThen (L.foldl go Dict.empty >> succeed)


decoderPresent =
    map3 (,,)
        (field "description" string)
        (maybe <| field "link" string)
        (maybe <| field "takenBy" string)


decoderMeta =
    Json.map UserMeta
        -- (field "uid" string)
        (field "name" string)



--


encodePresent : Present -> E.Value
encodePresent { description, link, takenBy } =
    [ ( "description", Just description ), ( "link", link ), ( "takenBy", takenBy ) ]
        |> L.filterMap encodeMaybe
        |> E.object


encodeMaybe : ( String, Maybe String ) -> Maybe ( String, E.Value )
encodeMaybe ( s, v ) =
    Maybe.map (E.string >> ((,) s)) v
