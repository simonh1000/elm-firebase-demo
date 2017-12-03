module Model exposing (..)

import Json.Decode as Json exposing (..)
import Json.Encode as E
import Dict exposing (Dict)
import List as L
import Common.CoreHelpers exposing (andMap)
import Firebase.Firebase as FB


type Page
    = InitAuth -- checking auth status
    | Subscribe -- making snapshot request
      --   | SetNotifications -- no specific UI consequnces in fact
    | Picker
    | MyClaims
    | Login
    | Register



-- type InitStatus


type alias Model =
    { page : Page
    , email : String
    , password : String
    , password2 : String
    , user : FB.FBUser
    , xmas : Dict String UserData
    , userMessage : String
    , editor : Present
    , editorCollapsed : Bool
    , isPhase2 : Bool
    , showSettings : Bool
    }


blank : Model
blank =
    { page = InitAuth
    , email = ""
    , password = ""
    , password2 = ""
    , user = FB.init
    , xmas = Dict.empty
    , userMessage = ""
    , editor = blankPresent
    , editorCollapsed = True
    , isPhase2 = False
    , showSettings = False
    }


type alias UserData =
    { meta : UserMeta
    , presents : Dict String Present
    }


type alias UserMeta =
    { name : String
    , notifications : Bool
    }


type alias Present =
    { uid : Maybe String
    , description : String
    , link : Maybe String
    , takenBy : Maybe String
    , purchased : Bool
    }


blankPresent : Present
blankPresent =
    { uid = Nothing
    , description = ""
    , link = Nothing
    , takenBy = Nothing
    , purchased = False
    }



--


prettyPrint : Page -> String
prettyPrint p =
    case p of
        InitAuth ->
            "Checking credentials"

        Subscribe ->
            "Getting presents data"

        _ ->
            toString p



-- DECODER


decoderXmas : Decoder (Dict String UserData)
decoderXmas =
    field "value" <|
        oneOf
            [ keyValuePairs decodeUserData
                |> map (L.map converter >> L.filterMap identity >> Dict.fromList)

            --  handle case where the database starts empty
            , null Dict.empty
            ]


converter : ( a, Maybe b ) -> Maybe ( a, b )
converter ( a, b ) =
    case b of
        Just b_ ->
            Just ( a, b_ )

        Nothing ->
            Nothing


decodeUserData : Decoder (Maybe UserData)
decodeUserData =
    oneOf
        [ map Just <|
            map2 UserData
                (field "meta" decoderMeta)
                (Json.oneOf [ field "presents" decodePresents, Json.succeed Dict.empty ])
        , succeed Nothing
        ]


decodePresents : Decoder (Dict String Present)
decodePresents =
    let
        go ( id, p ) ps =
            case decodeValue (decoderPresent id) p of
                Ok present ->
                    Dict.insert id present ps

                Err err ->
                    ps
    in
        keyValuePairs value
            |> andThen (L.foldl go Dict.empty >> succeed)


decoderPresent : String -> Decoder Present
decoderPresent id =
    succeed (Present <| Just id)
        |> andMap (field "description" string)
        |> andMap (maybe <| field "link" string)
        |> andMap (maybe <| field "takenBy" string)
        |> andMap (oneOf [ field "purchased" bool, succeed False ])


decoderMeta : Decoder UserMeta
decoderMeta =
    Json.map2 UserMeta
        (field "name" string)
        (oneOf [ field "notifications" bool, succeed True ])


decoderError : Decoder String
decoderError =
    field "message" string



-- Encoders


encodePresent : Present -> E.Value
encodePresent { description, link, takenBy } =
    let
        commonData =
            [ ( "description", Just description ), ( "takenBy", takenBy ) ]

        dataToEncode =
            case link of
                Just link_ ->
                    ( "link", Just link_ ) :: commonData

                Nothing ->
                    commonData
    in
        dataToEncode
            |> L.filterMap encodeMaybe
            |> E.object


encodeMaybe : ( String, Maybe String ) -> Maybe ( String, E.Value )
encodeMaybe ( s, v ) =
    Maybe.map (E.string >> ((,) s)) v
