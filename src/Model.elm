module Model exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode as E
import Dict exposing (Dict)
import List as L
import Firebase.Firebase as FB


type Page
    = Login
    | Register
    | Picker


type alias Model =
    { page : Page
    , email : String
    , password : String
    , password2 : String
    , user : FB.FBUser
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
    , user = FB.init
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



-- Model update helpers


updateEditor : (Present -> Present) -> Model -> Model
updateEditor fn model =
    { model | editor = fn model.editor }


setDisplayName : String -> Model -> Model
setDisplayName displayName model =
    let
        user =
            model.user
    in
        { model | user = { user | displayName = Just displayName } }



-- DECODER


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


decoderError =
    field "message" string



-- Encoders


encodePresent : Present -> E.Value
encodePresent { description, link, takenBy } =
    [ ( "description", Just description ), ( "link", link ), ( "takenBy", takenBy ) ]
        |> L.filterMap encodeMaybe
        |> E.object


encodeMaybe : ( String, Maybe String ) -> Maybe ( String, E.Value )
encodeMaybe ( s, v ) =
    Maybe.map (E.string >> ((,) s)) v
