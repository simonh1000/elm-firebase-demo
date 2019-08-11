module Model exposing (..)

import Common.CoreHelpers exposing (andMap, foldResult)
import Dict exposing (Dict)
import Firebase.Firebase as FB
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode
import List as L


type alias Model =
    { tab : AppTab
    , user : FB.FBUser
    , xmas : Dict String UserData
    , userMessage : Maybe String
    , editor : Present
    , editorCollapsed : Bool
    , isPhase2 : Bool
    }


blank : Model
blank =
    { tab = Family
    , user = FB.init
    , xmas = Dict.empty
    , userMessage = Nothing
    , editor = blankPresent
    , editorCollapsed = True
    , isPhase2 = False
    }


setDisplayName : String -> Model -> Model
setDisplayName displayName model =
    let
        user =
            model.user
    in
    { model | user = { user | displayName = Just displayName } }



-- -----------------------
-- AppTab
-- -----------------------


type AppTab
    = Family
    | MySuggestions
    | MyClaims
    | Settings


stringFromTab : AppTab -> ( String, String )
stringFromTab tab =
    case tab of
        Family ->
            ( "account-group", "Family" )

        MySuggestions ->
            ( "account", "Suggestions" )

        MyClaims ->
            ( "file-document-box-check-outline", "Claims" )

        Settings ->
            ( "settings", "" )



-- -----------------------
-- UserData
-- -----------------------


type alias UserData =
    { meta : UserMeta
    , presents : Dict String Present
    }


decoderUserData : String -> Decoder (Dict String UserData)
decoderUserData myId =
    field "value" <|
        oneOf
            [ keyValuePairs (decodeUserData myId)
                |> map (L.map converter >> L.filterMap identity >> Dict.fromList)

            --  handle case where the database starts empty
            , null Dict.empty
            ]


decodeUserData : String -> Decoder (Maybe UserData)
decodeUserData myId =
    oneOf
        [ map Just <|
            map2 UserData
                (field "meta" decodeUserMeta)
                (Decode.oneOf [ field "presents" (decodePresents myId), Decode.succeed Dict.empty ])
        , succeed Nothing
        ]


converter : ( a, Maybe b ) -> Maybe ( a, b )
converter ( a, b ) =
    case b of
        Just b_ ->
            Just ( a, b_ )

        Nothing ->
            Nothing



-- -----------------------
-- UserMeta
-- -----------------------


type alias UserMeta =
    { name : String
    , notifications : Bool
    }


decodeUserMeta : Decoder UserMeta
decodeUserMeta =
    Decode.map2 UserMeta
        (field "name" string)
        (oneOf [ field "notifications" bool, succeed True ])



-- DECODER


type alias Present =
    { uid : Maybe String
    , description : String
    , link : Maybe String
    , status : PresentStatus
    }


blankPresent : Present
blankPresent =
    { uid = Nothing
    , description = ""
    , link = Nothing
    , status = Available
    }


decodePresents : String -> Decoder (Dict String Present)
decodePresents myId =
    let
        go ( id, p ) ps =
            decodeValue (decoderPresent myId id) p
                |> Result.map (\present -> Dict.insert id present ps)

        decodeInner =
            foldResult go (Ok Dict.empty)
    in
    keyValuePairs value
        |> andThen
            (\lst ->
                case decodeInner lst of
                    Ok res ->
                        Decode.succeed res

                    Err err ->
                        Decode.fail <| Decode.errorToString err
            )


decoderPresent : String -> String -> Decoder Present
decoderPresent myId id =
    succeed (Present <| Just id)
        |> andMap (field "description" string)
        |> andMap (maybe <| field "link" string)
        |> andMap (decodePresentStatus myId)


encodePresent : String -> Present -> Encode.Value
encodePresent myId p =
    let
        commonData =
            ( "description", Encode.string p.description ) :: encodePresentStatus myId p.status

        dataToEncode =
            case p.link of
                Just link_ ->
                    ( "link", Encode.string link_ ) :: commonData

                Nothing ->
                    commonData
    in
    Encode.object dataToEncode



-- PresentStatus


type PresentStatus
    = Available
    | ClaimedByMe Bool -- purchased?
    | ClaimedBySomeone


decodePresentStatus : String -> Decoder PresentStatus
decodePresentStatus myId =
    field "takenBy" string
        |> Decode.maybe
        |> Decode.andThen
            (\val ->
                case val of
                    Just id ->
                        if id == myId then
                            oneOf [ field "purchased" bool, succeed False ]
                                |> Decode.map ClaimedByMe

                        else
                            Decode.succeed ClaimedBySomeone

                    Nothing ->
                        Decode.succeed Available
            )


encodePresentStatus : String -> PresentStatus -> List ( String, Value )
encodePresentStatus myId presentStatus =
    case presentStatus of
        ClaimedByMe _ ->
            -- TODO purchased???
            [ ( "takenBy", Encode.string myId ) ]

        _ ->
            []
