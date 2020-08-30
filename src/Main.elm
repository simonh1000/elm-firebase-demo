module Main exposing (main)

import App
import Auth
import Browser
import Common.CoreHelpers exposing (addCmd)
import Common.ViewHelpers as ViewHelpers
import Firebase.Firebase as FB exposing (AuthState(..), FBCommand(..), FBResponse(..), FBUser)
import Html exposing (..)
import Html.Attributes exposing (..)
import Json.Decode exposing (Decoder, Value)
import Json.Encode as Encode
import Model exposing (..)
import Ports



-- Init


type alias Flags =
    { cloudFunction : String
    , version : String

    -- TODO add phase 2 start
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( updateApp (\app -> { app | cloudFunction = flags.cloudFunction, version = flags.version }) blank
    , FB.setUpAuthListener
    )



-- Update


type Msg
    = AuthMsg Auth.Msg
    | AppMsg App.Msg
    | FirebasePortMsg FB.FBResponse


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

        FirebasePortMsg fbResponse ->
            case fbResponse of
                NewAuthState authstate ->
                    handleAuthChange authstate model

                Snapshot payload ->
                    handleSnapshot payload model

                MessagingToken token ->
                    -- will only happen once we are in main app
                    let
                        ( m, c ) =
                            App.handleToken token model.app
                    in
                    ( updateApp (\_ -> m) model, Cmd.map AppMsg c )

                NotificationsRefused ->
                    ( { model | userMessage = Just "NotificationsRefused" }, Cmd.none )

                NewNotification notification ->
                    --                    let
                    --                        _ =
                    --                            Debug.log "!!!!!" notification
                    --                    in
                    ( model, Cmd.none )

                Error err ->
                    update (AuthMsg <| Auth.OnLoginError err) model

                UnhandledResponse res ->
                    ( model
                    , Ports.rollbar <| "Need ports handler for " ++ res
                    )


{-| the user information is richer for a google login than for an email login
-}
handleAuthChange : AuthState -> Model -> ( Model, Cmd Msg )
handleAuthChange authState model =
    case authState of
        AuthenticatedUser user ->
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
            -- Next, subscribe to the db
            ( newModel, FB.subscribe "/" )

        NoUser ->
            ( { model
                | page = AuthPage
                , userMessage = Just "Please login"
              }
            , Cmd.none
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
            -- IMPOSSIBLE STATE!
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



-- CMDs


setMeta : String -> String -> Encode.Value -> Cmd msg
setMeta uid key val =
    FB.set ("/" ++ uid ++ "/meta/" ++ key) val



--


main =
    Browser.document
        { init = init
        , view = \m -> { title = ViewHelpers.title, body = [ view m ] }
        , update = update
        , subscriptions = \_ -> FB.subscriptions FirebasePortMsg
        }
