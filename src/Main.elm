module Main exposing (main)

import App
import Auth
import Browser
import Common.CoreHelpers exposing (addCmd)
import Common.ViewHelpers as ViewHelpers
import Firebase.Firebase as FB exposing (AuthState(..), FBCommand(..), FBResponse(..), FBUser)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Json.Decode exposing (Decoder, Value)
import Model exposing (..)
import Ports



-- Init


type alias Flags =
    { cloudFunction : String
    , version : String
    , phase2 : String
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( updateApp
        (\app ->
            { app
                | cloudFunction = flags.cloudFunction
                , version = flags.version
                , phase2 = flags.phase2
            }
        )
        blank
    , FB.setUpAuthListener
    )



-- Update


type Msg
    = AuthMsg Auth.Msg
    | AppMsg App.Msg
    | UpdateApp
    | FirebasePortMsg FB.FBResponse
    | NewPortMsg Ports.IncomingMsg


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

        UpdateApp ->
            ( { model | updateWaiting = False }, Ports.sendToJs Ports.SkipWaiting )

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

                PresentNotification notification ->
                    -- let
                    --     _ =
                    --         Debug.log "!!!!!" notification
                    -- in
                    ( model, Cmd.none )

                CustomNotification notification ->
                    --let
                    --    _ =
                    --        Debug.log "**custom**" notification
                    --in
                    ( model, Cmd.none )

                Error err ->
                    update (AuthMsg <| Auth.OnLoginError err) model

                UnhandledResponse res ->
                    ( model
                    , Ports.rollbar <| "Need port handler for" ++ res
                    )

        NewPortMsg incomingMsg ->
            case incomingMsg of
                Ports.NewCode _ ->
                    ( { model | updateWaiting = True }, Cmd.none )

                Ports.UnrecognisedPortMsg taggedPayload ->
                    --let
                    --    _ =
                    --        Debug.log " port" taggedPayload
                    --in
                    ( model, Cmd.none )


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
                |> addCmd (Cmd.map AppMsg (App.initCmd model.app.phase2))

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
                [ div [ class "logo-container" ] [ img [ src "images/icons/icon-192x192.png" ] [] ]
                , div [] [ img [ src "images/spinner.svg" ] [] ]
                , text txt
                ]
            , userMessage
            ]

        wrap mapper htm =
            div [ class "app d-flex flex-column" ]
                [ div [ class <| "d-flex flex-column " ++ String.toLower (stringFromPage model.page) ] htm
                    |> Html.map mapper
                , if model.updateWaiting then
                    button
                        [ class "btn btn-warning update-button"
                        , onClick UpdateApp
                        ]
                        [ text "Update App" ]

                  else
                    text ""
                ]
    in
    case model.page of
        InitAuth ->
            spinner "Checking credentials" |> wrap AuthMsg

        Subscribing _ ->
            spinner "Getting presents data" |> wrap AuthMsg

        AuthPage ->
            Auth.view model.auth |> wrap AuthMsg

        AppPage ->
            App.view model.app |> wrap AppMsg



-- CMDs
--setMeta : String -> String -> Encode.Value -> Cmd msg
--setMeta uid key val =
--    FB.set ("/" ++ uid ++ "/meta/" ++ key) val
--


main =
    Browser.document
        { init = init
        , view = \m -> { title = ViewHelpers.title, body = [ view m ] }
        , update = update
        , subscriptions =
            \_ ->
                Sub.batch
                    [ FB.subscriptions FirebasePortMsg
                    , Ports.fromJs (Ports.decodeIncomingMsg >> NewPortMsg)
                    ]
        }
