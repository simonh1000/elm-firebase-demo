port module Main exposing (main)

import App
import Auth
import Browser
import Common.CoreHelpers exposing (addCmd)
import Common.ViewHelpers as ViewHelpers
import Firebase.Firebase as FB exposing (FBCommand(..), FBResponse(..), FBUser)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Model as AppM exposing (Page(..))
import Ports



-- Model


type alias Model =
    { auth : Auth.Model
    , app : AppM.Model
    , page : Page
    , cloudFunction : String
    , userMessage : Maybe String
    }


blank : Model
blank =
    { auth = Auth.blank
    , app = AppM.blank
    , page = InitAuth
    , cloudFunction = ""
    , userMessage = Nothing
    }


updateApp : (AppM.Model -> AppM.Model) -> Model -> Model
updateApp fn model =
    { model | app = fn model.app }



--


type alias Flags =
    { now : Int }


init : String -> ( Model, Cmd Msg )
init cloudFunction =
    ( { blank | page = InitAuth, cloudFunction = cloudFunction }
    , Cmd.batch
        [ FB.setUpAuthListener
        , Ports.sendToJs <| Ports.RemoveAppShell ""
        ]
    )



--


type Msg
    = AuthMsg Auth.Msg
    | AppMsg App.Msg
    | FBMsgHandler FB.FBResponse


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
                    App.update model.cloudFunction msg model.app
            in
            ( { model | app = app }, Cmd.map AppMsg c )

        FBMsgHandler fbResponse ->
            case fbResponse of
                AuthState mbUser ->
                    handleAuthChange mbUser model

                Snapshot payload ->
                    handleSnapshot payload model

                MessagingToken token ->
                    ( updateApp (\m -> { m | messagingToken = Just token }) model, Cmd.none )

                NotificationsRefused ->
                    ( { model | userMessage = Just "NotificationsRefused" }, Cmd.none )

                NewNotification notification ->
                    --                    let
                    --                        _ =
                    --                            Debug.log "!!!!!" notification
                    --                    in
                    ( model, Cmd.none )

                CFError err ->
                    ( { model | userMessage = Just err }, Cmd.none )

                Error err ->
                    ( { model | userMessage = Just err }, Cmd.none )

                UnhandledResponse res ->
                    ( { model | userMessage = Just <| "Need handler for " ++ res }, Cmd.none )


{-| the user information is richer for a google login than for an email login
-}
handleAuthChange : Result String FBUser -> Model -> ( Model, Cmd Msg )
handleAuthChange mbUser model =
    case mbUser of
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
            ( { model | page = AuthPage, userMessage = Just "Unexpectedly lost details of the user" }, Cmd.none )

        Err err ->
            ( { model | page = AuthPage, userMessage = Just err }
            , Ports.sendToJs <| Ports.LogRollbar <| "handleAuthChange " ++ err
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
            div [ class <| "app " ++ String.toLower (AppM.stringFromPage model.page) ] htm
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



-- CMDs


setMeta : String -> String -> Encode.Value -> Cmd msg
setMeta uid key val =
    FB.set ("/" ++ uid ++ "/meta/" ++ key) val



--


main =
    Browser.document
        { init = init
        , view = \m -> { title = "Xmas 2019", body = [ view m ] }
        , update = update
        , subscriptions = \_ -> FB.subscriptions FBMsgHandler
        }
