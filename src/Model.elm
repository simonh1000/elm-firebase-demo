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
    , newPresent : String
    , newPresentLink : String
    , userMessage : String
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
    , newPresent = ""
    , newPresentLink = ""
    , userMessage = ""
    }


type alias AuthData =
    { email : String
    , uid : String
    }


blankUser =
    { email = ""
    , uid = ""
    }


type alias UserData =
    { meta : UserMeta
    , presents : Dict String Present
    }


type alias UserMeta =
    { name : String
    }


type alias Present =
    { description : String
    , takenBy : Maybe String
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
        (Json.oneOf [ field "presents" <| dict decoderPresent, Json.succeed Dict.empty ])


decoderPresent =
    map2 Present
        (field "description" string)
        (maybe <| field "takenBy" string)


decoderMeta =
    Json.map UserMeta
        -- (field "uid" string)
        (field "name" string)
