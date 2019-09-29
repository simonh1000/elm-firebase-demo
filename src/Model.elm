module Model exposing (..)

import Color exposing (Color)
import Common.CoreHelpers exposing (andMap, foldResult, ifThenElse)
import Dict exposing (Dict)
import Firebase.Firebase as FB exposing (FBUser)
import Json.Decode as Decode exposing (..)
import Json.Encode as Encode
import List as L
import Material.Icons.Action as MAction
import Material.Icons.Social as MSocial
import Svg exposing (Svg)



-- -----------------------
-- Main: Page
-- -----------------------


type Page
    = InitAuth -- checking auth status
    | Subscribing FB.FBUser -- making snapshot request
    | AuthPage
    | AppPage


stringFromPage : Page -> String
stringFromPage page =
    case page of
        InitAuth ->
            "InitAuth"

        Subscribing _ ->
            "Subscribing"

        AuthPage ->
            "AuthPage"

        AppPage ->
            "AppPage"



-- -----------------------
-- Main: UserMessage
-- -----------------------


type UserMessage
    = NoMessage
    | SuccessMessage String
    | ErrorMessage String



-- -----------------------
-- App: Model
-- -----------------------


type alias Model =
    { tab : AppTab
    , user : FBUser
    , messagingToken : Maybe String
    , userData : Dict String UserData
    , userMessage : UserMessage
    , editor : Present
    , editorCollapsed : Bool
    , isPhase2 : Bool
    }


blank : Model
blank =
    { tab = Family
    , user = FB.blankFBUser
    , messagingToken = Nothing
    , userData = Dict.empty
    , userMessage = NoMessage
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


stringFromTab : AppTab -> ( Color -> Int -> Svg msg, String )
stringFromTab tab =
    case tab of
        Family ->
            ( MSocial.people, "Family" )

        MySuggestions ->
            ( MSocial.person, "Suggestions" )

        MyClaims ->
            ( MAction.bookmark, "Claims" )

        Settings ->
            ( MAction.settings_application, "" )



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
            , --  handle case where the database starts empty
              null Dict.empty
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
    , notifications : Notifications
    }


decodeUserMeta : Decoder UserMeta
decodeUserMeta =
    Decode.map2 UserMeta
        (field "name" string)
        (oneOf [ decoderNotifications, succeed NotificationsUnset ])


type Notifications
    = YesPlease
    | NoThanks
    | NotificationsUnset


decoderNotifications : Decoder Notifications
decoderNotifications =
    let
        convert val =
            ifThenElse val YesPlease NoThanks
    in
    field "notifications" bool
        |> Decode.map convert


encodeNotifications : Notifications -> Maybe ( String, Value )
encodeNotifications n =
    case n of
        YesPlease ->
            Just ( "notifications", Encode.bool True )

        NoThanks ->
            Just ( "notifications", Encode.bool False )

        NotificationsUnset ->
            Nothing



-- -----------------------
-- Present
-- -----------------------


type alias Present =
    { uid : Maybe String
    , title : String
    , link : Maybe String
    , buyingAdvice : Maybe String
    , status : PresentStatus
    }


blankPresent : Present
blankPresent =
    { uid = Nothing
    , title = ""
    , link = Nothing
    , buyingAdvice = Nothing
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
        |> andMap (maybe <| field "buying-advice" string)
        |> andMap (decodePresentStatus myId)


encodePresent : String -> Present -> Encode.Value
encodePresent myId p =
    [ Just ( "description", Encode.string p.title )
    , encodePresentStatus myId p.status
    , p.link |> Maybe.map (\link_ -> ( "link", Encode.string link_ ))
    , p.buyingAdvice |> Maybe.map (\txt -> ( "buying-advice", Encode.string txt ))
    ]
        |> L.filterMap identity
        |> Encode.object



-- -----------------------
-- PresentStatus
-- -----------------------


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


encodePresentStatus : String -> PresentStatus -> Maybe ( String, Value )
encodePresentStatus myId presentStatus =
    case presentStatus of
        ClaimedByMe _ ->
            -- TODO purchased???
            Just ( "takenBy", Encode.string myId )

        _ ->
            Nothing
