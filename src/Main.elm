port module Main exposing (main)

import App
import Auth
import Browser
import Common.CoreHelpers exposing (debugALittle, recoverResult, updateAndThen)
import Common.ViewHelpers as ViewHelpers
import Firebase.Firebase as FB exposing (FBCommand(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Iso8601
import Json.Decode as Decode exposing (Decoder, Value)
import Json.Encode as Encode
import List as L
import Model as AppM
import Time exposing (Posix)


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


init : Flags -> ( Model, Cmd Msg )
init { now } =
    ( { blank
        | page = InitAuth

        --        , isPhase2 = checkIfPhase2 now
      }
    , Cmd.batch
        [ FB.setUpAuthListener
        , removeAppShell ""
        ]
    )



--


type Msg
    = AuthMsg Auth.Msg
    | AppMsg App.Msg
    | Signin String String
    | SigninGoogle
    | Register String String
    | FBMsgHandler FB.FBMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case Debug.log "update" message of
        AuthMsg msg ->
            let
                config =
                    { signin = Signin
                    , signinGoogle = SigninGoogle
                    , register = Register
                    }

                ( auth, c ) =
                    Auth.update config msg model.auth
            in
            ( { model | auth = auth }, c )

        AppMsg msg ->
            let
                ( app, c ) =
                    App.update msg model.app
            in
            ( { model | app = app }, Cmd.map AppMsg c )

        FBMsgHandler msg ->
            case msg.message of
                "authstate" ->
                    handleAuthChange msg.payload model

                "snapshot" ->
                    handleSnapshot msg.payload model

                --                "SubscriptionOk" ->
                --                    -- After Cloud Function returns successfully, update db to persist preference
                --                    ( { model | userMessage = Nothing }
                --                    , setMeta model.user.uid "notifications" <| Encode.bool True
                --                    )
                --
                --                "UnsubscribeOk" ->
                --                    -- After Cloud Function returns successfully, update db to persist preference
                --                    ( { model | userMessage = Nothing }
                --                    , setMeta model.user.uid "notifications" <| Encode.bool False
                --                    )
                "CFError" ->
                    let
                        userMessage =
                            Decode.decodeValue decoderError msg.payload
                                |> recoverResult Decode.errorToString
                    in
                    ( { model | userMessage = Just userMessage }
                    , Cmd.none
                    )

                "error" ->
                    let
                        userMessage =
                            Decode.decodeValue decoderError msg.payload
                                |> recoverResult Decode.errorToString
                    in
                    ( { model | userMessage = Just userMessage }
                    , Cmd.none
                    )

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

        _ ->
            ( model, Cmd.none )


handleAuthChange : Value -> Model -> ( Model, Cmd Msg )
handleAuthChange val model =
    case Decode.decodeValue FB.decodeAuthState val |> Result.mapError Decode.errorToString |> Result.andThen identity of
        -- If user exists, then subscribe to db changes
        Ok user ->
            let
                displayName =
                    case ( user.displayName, model.auth.displayName /= "" ) of
                        ( Nothing, True ) ->
                            Just model.auth.displayName

                        _ ->
                            user.displayName

                newModel =
                    { model
                        | page = Subscribing { user | displayName = displayName }
                        , userMessage = Nothing
                    }
            in
            ( newModel, FB.subscribe "/" )

        --            case ( user.displayName, model.user.displayName ) of
        --                ( Nothing, Just displayName ) ->
        --                    -- Have displayName: case occurs immediately after new Email registration
        --
        --                -- (Just _, Nothing) -> standard startup
        --                -- (Just _, Just _) -> not sure this is possible
        --                -- (Nothing, Nothing) -> Occurs when a non-Google user reloads page. Username will come with first snapshot
        --                _ ->
        --                    -- at this stage we could update the DB with this info, but we cannot know whether it is necessary
        --                    ( { newModel | user = user }
        --                    , FB.subscribe "/"
        --                    )
        --
        Err "nouser" ->
            ( { model | page = AuthPage }, Cmd.none )

        Err err ->
            ( { model | page = AuthPage, userMessage = Just err }
            , rollbar <| "handleAuthChange " ++ err
            )


{-| If snapshot lacks displayName, then add it to the DB
Now we have the (possible) notifications preference, so use that

FIXME we are renewing subscriptions everytime a subscription comes in

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

        AppPage ->
            update (AppMsg <| App.HandleSnapshot Nothing payload) newModel

        _ ->
            Debug.todo "handleSnapshot"


decoderError : Decoder String
decoderError =
    Decode.field "message" Decode.string



--


view : Model -> Html Msg
view model =
    let
        spinner txt =
            div [ class <| "app " ++ String.toLower (Debug.toString model.page) ]
                [ ViewHelpers.simpleHeader
                , div [ class "loading" ]
                    [ img [ src "spinner.svg" ] []
                    , div [] [ text txt ]
                    ]
                , userMessage
                ]

        userMessage =
            model.userMessage
                |> Maybe.map (\txt -> div [ class "container warning" ] [ text txt ])
                |> Maybe.withDefault (text "")
    in
    case model.page of
        InitAuth ->
            spinner "Checking credentials"

        Subscribing _ ->
            spinner "Getting presents data"

        AuthPage ->
            Auth.view model.auth |> Html.map AuthMsg

        --                Register ->
        --                    [ viewRegister model ]
        AppPage ->
            -- Picker and Claims
            --                    [ model.xmas
            --                        |> Dict.get model.user.uid
            --                        |> Maybe.map (.meta >> .notifications)
            --                        |> Maybe.withDefault True
            --                        |> sidebar model
            --                    , viewPicker model
            --                    ]
            App.view model.app |> Html.map AppMsg



--


type Page
    = InitAuth -- checking auth status
    | Subscribing FB.FBUser -- making snapshot request
    | AuthPage
    | AppPage



--


checkIfPhase2 : Int -> Bool
checkIfPhase2 now =
    case Debug.log "" <| Iso8601.toTime "2018-10-01" of
        Ok endPhase1 ->
            (now * 1000) > Time.posixToMillis endPhase1

        Err _ ->
            False



--
-- CMDs
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


setMeta : String -> String -> Encode.Value -> Cmd msg
setMeta uid key val =
    FB.set ("/" ++ uid ++ "/meta/" ++ key) val


makeSetPresentRef : String -> String -> String -> String
makeSetPresentRef str otherRef presentRef =
    [ otherRef, "presents", presentRef, str ] |> String.join "/"



--


main =
    Browser.document
        { init = init
        , view = \m -> { title = "new app", body = [ view m ] }
        , update = update
        , subscriptions =
            always (FB.subscriptions FBMsgHandler)
        }
