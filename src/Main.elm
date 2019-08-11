port module Main exposing (main)

import App
import Auth
import Browser
import Common.CoreHelpers exposing (addCmd, recoverResult)
import Common.ViewHelpers as ViewHelpers
import Firebase.Firebase as FB exposing (FBCommand(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Model as AppM


port removeAppShell : String -> Cmd msg


port rollbar : String -> Cmd msg



--


type alias Model =
    { auth : Auth.Model
    , app : AppM.Model
    , page : Page
    , userMessage : Maybe String
    }


blank : Model
blank =
    { auth = Auth.blank
    , app = AppM.blank
    , page = InitAuth
    , userMessage = Nothing
    }



--


type alias Flags =
    { now : Int }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { blank | page = InitAuth }
    , Cmd.batch
        [ FB.setUpAuthListener
        , removeAppShell ""
        ]
    )



--


type Msg
    = AuthMsg Auth.Msg
    | AppMsg App.Msg
    | FBMsgHandler FB.FBMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        AuthMsg msg ->
            let
                ( auth, c ) =
                    Auth.update msg model.auth
            in
            ( { model | auth = auth }, c )

        AppMsg msg ->
            let
                ( app, c ) =
                    App.update msg model.app
            in
            ( { model | app = app }, Cmd.map AppMsg c )

        FBMsgHandler msg ->
            case Debug.log "FBMsgHandler" msg.message of
                "authstate" ->
                    handleAuthChange msg.payload model

                "snapshot" ->
                    handleSnapshot msg.payload model

                "SubscriptionOk" ->
                    -- After Cloud Function returns successfully, update db to persist preference
                    ( model
                    , setMeta model.app.user.uid "notifications" <| Encode.bool True
                    )

                "UnsubscribeOk" ->
                    -- After Cloud Function returns successfully, update db to persist preference
                    ( model
                    , setMeta model.app.user.uid "notifications" <| Encode.bool False
                    )

                "CFError" ->
                    let
                        userMessage =
                            Decode.decodeValue decoderError msg.payload
                                |> recoverResult Decode.errorToString
                                |> Just
                    in
                    ( { model | userMessage = userMessage }, Cmd.none )

                "error" ->
                    let
                        userMessage =
                            Decode.decodeValue decoderError msg.payload
                                |> recoverResult Decode.errorToString
                                |> Just
                    in
                    ( { model | userMessage = userMessage }, Cmd.none )

                "token-refresh" ->
                    let
                        _ =
                            Debug.log "token-refresh" msg.payload
                    in
                    ( model, Cmd.none )

                _ ->
                    let
                        _ =
                            Debug.log "********Unhandled Incoming FBMsg" message
                    in
                    ( model, Cmd.none )


{-| the user information is richer for a google login than for an email login
-}
handleAuthChange : Value -> Model -> ( Model, Cmd Msg )
handleAuthChange val model =
    case Decode.decodeValue FB.decodeAuthState val |> Result.mapError Decode.errorToString |> Result.andThen identity of
        Ok user ->
            let
                displayName =
                    case ( user.displayName, model.auth.displayName /= "" ) of
                        -- just after registering for email login
                        ( Nothing, True ) ->
                            Just model.auth.displayName

                        _ ->
                            -- (Nothing, False) -> email login, but we expect the displayName will be in snapshot
                            -- (Just _, _) -> google login
                            user.displayName

                newModel =
                    { model
                        | page = Subscribing { user | displayName = displayName }
                        , userMessage = Nothing
                    }
            in
            -- If user exists, then subscribe to db changes
            ( newModel, FB.subscribe "/" )

        Err "nouser" ->
            let
                _ =
                    Debug.log "handleAuthChange" "nouser"
            in
            ( { model | page = AuthPage }, Cmd.none )

        Err err ->
            ( { model | page = AuthPage, userMessage = Just err }
            , rollbar <| "handleAuthChange " ++ err
            )


{-| If snapshot lacks displayName, then add it to the DB
Now we have the (possible) notifications preference, so use that

FIXME we are renewing subscriptions every time a subscription comes in

-}
handleSnapshot : Value -> Model -> ( Model, Cmd Msg )
handleSnapshot payload model =
    let
        newModel =
            { model | page = AppPage }
    in
    case model.page of
        Subscribing user ->
            update (AppMsg <| App.HandleSnapshot (Just user) payload) newModel
                |> addCmd (Cmd.map AppMsg App.initCmd)

        AppPage ->
            update (AppMsg <| App.HandleSnapshot Nothing payload) newModel

        _ ->
            -- not clear how we could reach here for any other page
            ( model, Cmd.none )


decoderError : Decoder String
decoderError =
    Decode.field "message" Decode.string



--


view : Model -> Html Msg
view model =
    let
        userMessage =
            model.userMessage
                |> Maybe.map (\txt -> footer [ class "container warning" ] [ text txt ])
                |> Maybe.withDefault (text "")

        spinner txt =
            [ ViewHelpers.simpleHeader
            , div [ class "main loading" ]
                [ img [ src "spinner.svg" ] []
                , div [] [ text txt ]
                ]
            , userMessage
            ]

        wrap htm =
            div [ class <| "app " ++ String.toLower (stringFromPage model.page) ] htm
    in
    case model.page of
        InitAuth ->
            spinner "Checking credentials" |> wrap

        Subscribing _ ->
            spinner "Getting presents data" |> wrap

        AuthPage ->
            Auth.view model.auth |> wrap |> Html.map AuthMsg

        AppPage ->
            App.view model.app |> wrap |> Html.map AppMsg



--


type Page
    = InitAuth -- checking auth status
    | Subscribing FB.FBUser -- making snapshot request
    | AuthPage
    | AppPage


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



-- CMDs


setMeta : String -> String -> Encode.Value -> Cmd msg
setMeta uid key val =
    FB.set ("/" ++ uid ++ "/meta/" ++ key) val



--claim : String -> String -> String -> Cmd msg
--claim uid otherRef presentRef =
--    FB.set
--        (makeSetPresentRef "takenBy" otherRef presentRef)
--        (Encode.string uid)
--
--
--purchase : String -> String -> Bool -> Cmd msg
--purchase otherRef presentRef purchased =
--    FB.set
--        (makeSetPresentRef "purchased" otherRef presentRef)
--        (Encode.bool purchased)
--
--
--unclaim : String -> String -> Cmd msg
--unclaim otherRef presentRef =
--    FB.remove <| makeSetPresentRef "takenBy" otherRef presentRef
--
--
--delete : Model -> String -> Cmd Msg
--delete model ref =
--    FB.remove ("/" ++ model.user.uid ++ "/presents/" ++ ref)
--
--
--savePresent : Model -> Cmd Msg
--savePresent model =
--    case model.editor.uid of
--        Just uid_ ->
--            -- update existing present
--            FB.set ("/" ++ model.user.uid ++ "/presents/" ++ uid_) (encodePresent model.editor)
--
--        Nothing ->
--            FB.push ("/" ++ model.user.uid ++ "/presents") (encodePresent model.editor)
--makeSetPresentRef : String -> String -> String -> String
--makeSetPresentRef str otherRef presentRef =
--    [ otherRef, "presents", presentRef, str ] |> String.join "/"
--


main =
    Browser.document
        { init = init
        , view = \m -> { title = "new app", body = [ view m ] }
        , update = update
        , subscriptions =
            always (FB.subscriptions FBMsgHandler)
        }
