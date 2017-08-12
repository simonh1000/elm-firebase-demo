port module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json exposing (Value)
import Json.Encode as E
import Date exposing (Date)
import Time exposing (Time)
import Dict exposing (Dict)
import List as L
import Firebase.Firebase as FB
import Model as M exposing (..)
import Bootstrap as B
import Jwt
import Jwt.Decoders


port removeAppShell : String -> Cmd msg


port expander : String -> Cmd msg



--


type alias Flags =
    { now : Time }


canShowWants : Time -> Bool
canShowWants t =
    case Date.fromString "1 sept 2017" |> Result.map Date.toTime of
        Ok b ->
            t > b

        Err _ ->
            False


init : Flags -> ( Model, Cmd Msg )
init { now } =
    { blank | showWants = canShowWants now }
        ! [ FB.setUpAuthListener
          , FB.requestMessagingPermission
          , removeAppShell ""
          ]



-- UPDATE


type Msg
    = UpdateEmail String
    | UpdatePassword String
    | UpdatePassword2 String
    | UpdateUsername String
    | Submit
    | SwitchTo Page
    | SubmitRegistration
    | GoogleSignin
      --
    | Signout
    | Claim String String
    | Unclaim String String
      -- Editor
    | UpdateNewPresent String
    | UpdateNewPresentLink String
    | SubmitNewPresent
    | CancelEditor
    | DeletePresent
      -- My presents list
    | Expander
    | EditPresent Present
      -- Subscriptions
    | FBMsgHandler FB.FBMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        UpdateEmail email ->
            { model | email = email } ! []

        UpdatePassword password ->
            { model | password = password } ! []

        Submit ->
            model ! [ FB.signin model.email model.password ]

        GoogleSignin ->
            model ! [ FB.signinGoogle ]

        -- Registration page
        SwitchTo page ->
            { model | page = page } ! []

        SubmitRegistration ->
            model ! [ FB.register model.email model.password ]

        UpdatePassword2 password2 ->
            { model | password2 = password2 } ! []

        UpdateUsername displayName ->
            setDisplayName displayName model ! []

        -- Main page
        Signout ->
            blank ! [ FB.signout ]

        Claim otherRef presentRef ->
            model ! [ claim model.user.uid otherRef presentRef ]

        Unclaim otherRef presentRef ->
            model ! [ unclaim otherRef presentRef ]

        UpdateNewPresent description ->
            updateEditor (\ed -> { ed | description = description }) model ! []

        UpdateNewPresentLink link ->
            updateEditor (\ed -> { ed | link = Just link }) model ! []

        SubmitNewPresent ->
            { model | editor = blankPresent } ! [ savePresent model ]

        CancelEditor ->
            { model | editor = blankPresent } ! []

        DeletePresent ->
            { model | editor = model.editor } ! []

        -- New present form
        Expander ->
            ( { model | editorCollapsed = not model.editorCollapsed }, Cmd.none )

        EditPresent newPresent ->
            updateEditor (\_ -> newPresent) model ! []

        FBMsgHandler { message, payload } ->
            case message of
                "authstate" ->
                    handleAuthChange payload model

                "snapshot" ->
                    handleSnapshot payload model

                "token" ->
                    -- let
                    --     _ =
                    --         Debug.log "payload" payload
                    --
                    --     _ =
                    --         Debug.log ""
                    --             (Json.decodeValue (Json.field "accessToken" <| Jwt.tokenDecoder Jwt.Decoders.firebase) payload)
                    -- in
                    ( model, Cmd.none )

                "error" ->
                    let
                        userMessage =
                            Json.decodeValue decoderError payload
                                |> Result.withDefault model.userMessage
                    in
                        { model | userMessage = userMessage } ! []

                _ ->
                    model ! []


handleAuthChange : Value -> Model -> ( Model, Cmd Msg )
handleAuthChange val model =
    case Json.decodeValue FB.decodeAuthState val |> Result.andThen identity of
        -- If user exists, then subscribe to db changes
        Ok user ->
            ( { model | user = user, page = Picker }
            , FB.subscribe "/"
            )

        Err err ->
            { model | user = FB.init, page = Login, userMessage = err } ! []


{-| In addition to the present data, we also possibly get a real name registered by
email/password users
-}
handleSnapshot snapshot model =
    case Json.decodeValue decoderXmas snapshot of
        Ok xmas ->
            case Dict.get model.user.uid xmas of
                -- If there is data for this user, then copy over the Name field
                Just userData ->
                    ( { model | xmas = xmas }
                        |> setDisplayName userData.meta.name
                    , Cmd.none
                    )

                -- If no data, then we should set the Name field using local data
                Nothing ->
                    case model.user.displayName of
                        Just displayName ->
                            { model | xmas = xmas } ! [ setMeta model.user.uid displayName ]

                        Nothing ->
                            { model | xmas = xmas } ! []

        Err err ->
            { model | userMessage = "handleSnapshot: " ++ err } ! []



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "app" ] <|
        case model.page of
            Loading ->
                [ simpleHeader
                , h1 [] [ text "Loading..." ]
                ]

            Login ->
                [ simpleHeader
                , viewLogin model
                ]

            Register ->
                [ simpleHeader
                , viewRegister model
                ]

            Picker ->
                [ viewHeader model
                , viewPicker model
                ]
                    ++ [ div [ class "warning" ] [ text model.userMessage ]
                       , viewFooter
                       ]


simpleHeader : Html msg
simpleHeader =
    header []
        [ div [ class "container" ]
            [ div [ class "flex-h spread" ] [ text "Xmas Present ideas" ] ]
        ]


viewHeader : Model -> Html Msg
viewHeader model =
    header []
        [ div [ class "container" ]
            [ div [ class "flex-h spread" ]
                [ div []
                    [ case model.user.photoURL of
                        Just photoURL ->
                            img [ src photoURL, class "avatar", alt "avatar" ] []

                        Nothing ->
                            text ""
                    , model.user.displayName
                        |> Maybe.map (text >> L.singleton >> strong [])
                        |> Maybe.withDefault (text "Xmas Present ideas")
                    ]
                , button [ class "btn btn-outline-warning btn-sm", onClick Signout ] [ text "Signout" ]
                ]
            ]
        ]


viewFooter : Html msg
viewFooter =
    footer []
        [ div [ class "container" ]
            [ div [ class "flex-h spread" ]
                [ a [ href "https://simonh1000.github.io/" ] [ text "Simon Hampton" ]
                , span [] [ text "May 2017" ]
                , a [ href "https://github.com/simonh1000/elm-firebase-demo" ] [ text "Code" ]
                ]
            ]
        ]



-- Main Page


viewPicker : Model -> Html Msg
viewPicker model =
    let
        ( mine, others ) =
            model.xmas
                |> Dict.toList
                |> L.partition (Tuple.first >> ((==) model.user.uid))
    in
        div [ id "picker", class "main container" ]
            [ div [ class "row" ]
                [ viewMine model mine
                , viewOthers model others
                ]
            ]



-- LHS


viewOthers : Model -> List ( String, UserData ) -> Html Msg
viewOthers model others =
    let
        wishes =
            if model.showWants then
                L.map (viewOther model) others
            else
                [ text "You will be able to see other wishes in due course" ]
    in
        div [ class "others col-12 col-sm-6" ] <|
            h2 [] [ text "Xmas wishes" ]
                :: wishes


viewOther : Model -> ( String, UserData ) -> Html Msg
viewOther model ( userRef, { meta, presents } ) =
    let
        viewPresent presentRef present =
            case present.takenBy of
                Just id ->
                    if model.user.uid == id then
                        li [ class "present flex-h", onClick <| Unclaim userRef presentRef ]
                            [ makeDescription present
                            , badge "success clickable" "Claimed"
                            ]
                    else
                        li [ class "present flex-h" ]
                            [ makeDescription present
                            , badge "warning" "Taken"
                            ]

                Nothing ->
                    li [ class "present flex-h" ]
                        [ makeDescription present
                        , button
                            [ class "btn btn-primary btn-sm"
                            , onClick <| Claim userRef presentRef
                            ]
                            [ text "Claim" ]
                        ]

        ps =
            presents
                |> Dict.map viewPresent
                |> Dict.values
    in
        case ps of
            [] ->
                text ""

            _ ->
                div [ class "person section" ] [ h4 [] [ text meta.name ], ul [] ps ]


badge : String -> String -> Html msg
badge cl t =
    span [ class <| "badge badge-" ++ cl ] [ text t ]



-- RHS


viewMine : Model -> List ( String, UserData ) -> Html Msg
viewMine model lst =
    let
        mypresents =
            case lst of
                [ ( _, { presents } ) ] ->
                    case Dict.values presents of
                        [] ->
                            text "Time to add you first idea!"

                        lst ->
                            lst
                                |> L.map viewMyPresentIdea
                                |> ul []

                [] ->
                    text "Time to add you first idea!"

                _ ->
                    text <| "error" ++ toString lst
    in
        div [ class "my-ideas col-sm-6" ]
            [ h2 []
                [ text "My suggestions"

                -- , button [ onClick Expander ] [ text "expand" ]
                ]
            , viewNewIdeaForm model
            , div [ class "my-presents section" ] [ mypresents ]
            ]


viewNewIdeaForm : Model -> Html Msg
viewNewIdeaForm { editor, editorCollapsed } =
    let
        btn msg txt =
            button
                [ class "btn btn-primary"
                , onClick msg
                , disabled <| editor.description == ""
                ]
                [ text txt ]

        mkAttrs s =
            if editorCollapsed then
                s ++ " collapsed"
            else
                s
    in
        div [ class <| mkAttrs "new-present section" ]
            [ h4 []
                [ case editor.uid of
                    Just _ ->
                        text "Editor"

                    Nothing ->
                        text "New suggestion"
                ]
            , div [ id "new-present-form" ]
                [ B.inputWithLabel UpdateNewPresent "Description" "newpresent" editor.description
                , editor.link
                    |> Maybe.withDefault ""
                    |> B.inputWithLabel UpdateNewPresentLink "Link (optional)" "newpresentlink"
                , div [ class "flex-h spread" ]
                    [ btn SubmitNewPresent "Save"
                    , if isJust editor.uid then
                        button [ class "btn btn-danger", disabled True ] [ text "Delete*" ]
                      else
                        text ""
                    , btn CancelEditor "Cancel"
                    ]
                , if isJust editor.uid then
                    p [] [ text "* Warning: someone may already have commited to buy this!" ]
                  else
                    text ""
                ]
            ]


viewMyPresentIdea : Present -> Html Msg
viewMyPresentIdea present =
    li [ class "present flex-h spread" ]
        [ makeDescription present
        , span [ class "material-icons clickable", onClick (EditPresent present) ] [ text "mode_edit" ]
        ]


makeDescription : Present -> Html Msg
makeDescription { description, link } =
    case link of
        Just link_ ->
            a [ href link_, target "_blank" ] [ text description ]

        Nothing ->
            text description



--


viewLogin : Model -> Html Msg
viewLogin model =
    div [ id "login", class "main container" ]
        [ div [ class "section google" ]
            [ h4 [] [ text "Either sign in with Google..." ]
            , img
                [ src "images/google_signin.png"
                , onClick GoogleSignin
                , alt "Click to sigin with Google"
                ]
                []
            ]
        , div [ class "section" ]
            [ h4 [] [ text "...Or with your email address" ]
            , Html.form
                [ onSubmit Submit ]
                [ B.inputWithLabel UpdateEmail "Email" "email" model.email
                , B.passwordWithLabel UpdatePassword "Password" "password" model.password
                , div [ class "flex-h spread" ]
                    [ button [ type_ "submit", class "btn btn-primary" ] [ text "Login" ]
                    , button [ type_ "button", class "btn btn-default", onClick (SwitchTo Register) ] [ text "New? Register yourself" ]
                    ]
                ]
            ]
        ]


viewRegister : Model -> Html Msg
viewRegister model =
    div [ id "register", class "main container" ]
        [ h1 [] [ text "Register" ]
        , Html.form
            [ onSubmit SubmitRegistration, class "section" ]
            [ B.inputWithLabel UpdateUsername "Your Name" "name" (Maybe.withDefault "" model.user.displayName)
            , B.inputWithLabel UpdateEmail "Email" "email" model.email
            , B.passwordWithLabel UpdatePassword "Password" "password" model.password
            , B.passwordWithLabel UpdatePassword2 "Retype Password" "password2" model.password2
            , div [ class "flex-h spread" ]
                [ button
                    [ type_ "submit"
                    , class "btn btn-primary"
                    , disabled <| model.password == "" || model.password /= model.password2
                    ]
                    [ text "Register" ]
                , button
                    [ class "btn btn-default"
                    , onClick (SwitchTo Login)
                    ]
                    [ text "Login" ]
                ]
            ]
        ]



--


isJust : Maybe a -> Bool
isJust =
    Maybe.map (\_ -> True) >> Maybe.withDefault False



-- CMDs


claim uid otherRef presentRef =
    FB.set
        (makeTakenByRef otherRef presentRef)
        (E.string uid)


unclaim otherRef presentRef =
    FB.remove <| makeTakenByRef otherRef presentRef


delete model ref =
    FB.remove ("/" ++ model.user.uid ++ "/presents/" ++ ref)


savePresent : Model -> Cmd Msg
savePresent model =
    case model.editor.uid of
        Just uid_ ->
            -- update existing present
            FB.set ("/" ++ model.user.uid ++ "/presents/" ++ uid_) (encodePresent model.editor)

        Nothing ->
            FB.push ("/" ++ model.user.uid ++ "/presents") (encodePresent model.editor)


setMeta : String -> String -> Cmd msg
setMeta uid name =
    FB.set (uid ++ "/meta") (E.object [ ( "name", E.string name ) ])


makeTakenByRef : String -> String -> String
makeTakenByRef otherRef presentRef =
    otherRef ++ "/presents/" ++ presentRef ++ "/takenBy"
