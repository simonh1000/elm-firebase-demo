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
import Common.CoreHelpers exposing (debugALittle)
import Firebase.Firebase as FB
import Model as M exposing (..)
import Bootstrap as B


port removeAppShell : String -> Cmd msg


port expander : String -> Cmd msg


port rollbar : String -> Cmd msg



--


type alias Flags =
    { now : Time }


isPhase2 : Time -> Bool
isPhase2 now =
    case Date.fromString "15 oct 2017" |> Result.map Date.toTime of
        Ok endPhase1 ->
            now > endPhase1

        Err _ ->
            False


init : Flags -> ( Model, Cmd Msg )
init { now } =
    { blank | isPhase2 = isPhase2 now }
        ! [ FB.setUpAuthListener

          --   , FB.requestMessagingPermission
          , removeAppShell ""
          ]



-- UPDATE


type Msg
    = UpdateEmail String
    | UpdatePassword String
    | UpdatePassword2 String
    | UpdateUsername String
    | Submit
    | SubmitRegistration
    | GoogleSignin
    | SwitchTo Page
      --
    | ToggleNotifications Bool
    | Signout
    | ToggleSidebar
    | Claim String String
    | Unclaim String String
    | TogglePurchased String String Bool -- other user ref, present ref, new value
      -- Editor
    | UpdateNewPresent String
    | UpdateNewPresentLink String
    | SubmitNewPresent
    | CancelEditor
    | DeletePresent String
      -- My presents list
    | Expander
    | EditPresent Present
      -- Subscriptions
    | FBMsgHandler FB.FBMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case debugALittle message of
        UpdateEmail email ->
            { model | email = email } ! []

        UpdatePassword password ->
            { model | password = password } ! []

        Submit ->
            { model | userMessage = "", page = Loading } ! [ FB.signin model.email model.password ]

        GoogleSignin ->
            { model | userMessage = "", page = Loading } ! [ FB.signinGoogle ]

        -- Registration page
        SwitchTo page ->
            { model | page = page } ! []

        SubmitRegistration ->
            { model | userMessage = "" } ! [ FB.register model.email model.password ]

        UpdatePassword2 password2 ->
            { model | password2 = password2 } ! []

        UpdateUsername userName ->
            setDisplayName userName model ! []

        -- Main page
        ToggleSidebar ->
            ( { model | showSettings = not model.showSettings }, Cmd.none )

        ToggleNotifications notifications ->
            ( model, setMeta model.user.uid "notifications" <| E.bool notifications )

        -- , FB.set model.user.uid "notifications" <|E.bool notifications )
        Signout ->
            blank ! [ FB.signout ]

        Claim otherRef presentRef ->
            model ! [ claim model.user.uid otherRef presentRef ]

        Unclaim otherRef presentRef ->
            ( model
            , Cmd.batch
                [ unclaim otherRef presentRef

                -- must also set as unpurchased
                , purchase otherRef presentRef False
                ]
            )

        TogglePurchased otherRef presentRef newValue ->
            ( model, purchase otherRef presentRef newValue )

        UpdateNewPresent description ->
            updateEditor (\ed -> { ed | description = description }) model ! []

        UpdateNewPresentLink link ->
            updateEditor
                (\ed ->
                    { ed
                        | link =
                            if link == "" then
                                Nothing
                            else
                                Just link
                    }
                )
                model
                ! []

        SubmitNewPresent ->
            { model | editor = blankPresent } ! [ savePresent model ]

        CancelEditor ->
            { model | editor = blankPresent } ! []

        DeletePresent uid ->
            { model | editor = blankPresent } ! [ delete model uid ]

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
            case ( user.displayName, model.user.displayName ) of
                ( Nothing, Just displayName ) ->
                    -- This case occurs immediately after new Email registration
                    ( { model
                        | user = { user | displayName = Just displayName }
                        , page = Picker
                        , userMessage = ""
                      }
                    , Cmd.batch [ FB.subscribe "/" ]
                    )

                _ ->
                    -- (Just displayName, Nothing) ->
                    -- at this stage we could update the DB with this info, but we cannot know whether it is necessary
                    ( { model
                        | user = user
                        , page = Picker
                        , userMessage = ""
                      }
                    , FB.subscribe "/"
                    )

        -- (Nothing, Nothing) ->
        --     ( { model | userMessage = "Unexpected error: no userName present"
        --       }
        --     , FB.subscribe "/"
        --     )
        -- ( Nothing, Nothing ) ->
        --     -- Occurs when a non-Google user reloads page
        --     ( { model | userMessage = "handleAuthChange missing userName" }, Cmd.none )
        Err "nouser" ->
            ( { model | user = FB.init, page = Login }, Cmd.none )

        Err err ->
            ( { model | user = FB.init, page = Login, userMessage = err }
            , rollbar <| "handleAuthChange " ++ err
            )


{-| In addition to the present data, we also possibly get a real name registered by
email/password users
-}
handleSnapshot : Value -> Model -> ( Model, Cmd Msg )
handleSnapshot snapshot model =
    case Json.decodeValue decoderXmas snapshot of
        Ok xmas ->
            case ( Dict.get model.user.uid xmas, model.user.displayName ) of
                -- User already registered; copy over userName
                ( Just userData, Nothing ) ->
                    ( { model | xmas = xmas }
                        |> setDisplayName userData.meta.name
                    , Cmd.none
                    )

                ( Nothing, Nothing ) ->
                    ( { model | userMessage = "Unexpected error - no username present" }, Cmd.none )

                ( Nothing, Just displayName ) ->
                    -- Either from the registration or the FB Google user data
                    -- we have the username and the database does not know it
                    ( { model | xmas = xmas }, setMeta model.user.uid "name" <| E.string displayName )

                ( Just _, Just _ ) ->
                    -- all subsequent snapshots
                    ( { model | xmas = xmas }, Cmd.none )

        Err err ->
            ( { model | userMessage = "handleSnapshot: " ++ err }
            , rollbar <| "handleSnapshot: " ++ err
            )



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ if L.member model.page [] then
            simpleHeader
          else
            viewNavbar model
        , div [ class <| "main " ++ String.toLower (toString model.page) ] <|
            case model.page of
                Loading ->
                    [ div [ class "loading" ] [ img [ src "spinner.svg" ] [] ] ]

                Login ->
                    [ viewLogin model ]

                Register ->
                    [ viewRegister model ]

                _ ->
                    [ model.xmas
                        |> Dict.get model.user.uid
                        |> Maybe.map (.meta >> .notifications)
                        |> Maybe.withDefault True
                        |> sidebar model.showSettings
                    , viewPicker model
                    ]
        , div [ class "container warning" ] [ text model.userMessage ]
        , viewFooter
        ]


sidebar showSettings notifications =
    div
        [ if showSettings then
            class "sidebar open"
          else
            class "sidebar"
        ]
        [ ul [ class "sidebar-inner" ]
            [ li [ class "sidebar-menu-item", onClick (ToggleNotifications <| not notifications) ]
                [ if notifications then
                    text "Notifications: On"
                  else
                    text "Notifications: Off"
                ]
            , li [ class "sidebar-menu-item", onClick Signout ] [ text "Signout" ]
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
        div [ id "picker", class "container" ]
            [ div [ class "row" ]
                [ viewMine model mine
                , if model.page == Picker then
                    viewOthers model others
                  else
                    viewClaims model others
                ]
            ]



-- RHS


viewClaims : Model -> List ( String, UserData ) -> Html Msg
viewClaims model others =
    let
        mkItem oRef presentRef present =
            let
                ( status, cls ) =
                    if present.purchased then
                        ( "Purchased", class "btn btn-success btn-sm" )
                    else
                        ( "Claimed", class "btn btn-warning btn-sm" )
            in
                li [ class "present flex-h spread" ]
                    [ makeDescription present
                    , button [ onClick <| TogglePurchased oRef presentRef (not present.purchased), cls ] [ text status ]
                    ]

        mkItemsForPerson ( oRef, other ) =
            div [ class "person section" ]
                [ h4 [] [ text other.meta.name ]
                , other.presents
                    |> filterMyClaims
                    |> Dict.map (mkItem oRef)
                    |> Dict.values
                    |> ul []
                ]

        filterMyClaims =
            Dict.filter (\_ v -> v.takenBy == Just model.user.uid)

        addORef oRef ( pRef, p ) =
            ( oRef, pRef, p )

        claims =
            others
                |> L.map mkItemsForPerson
                |> div []

        title =
            div [ class "title flex-h spread flex-baseline" ]
                [ h2 [] [ text "My Claims" ]
                , button [ onClick (SwitchTo Picker) ] [ text "My Family" ]
                ]
    in
        div [ class "claims col-12 col-sm-6" ]
            [ title
            , claims
            ]


viewOthers : Model -> List ( String, UserData ) -> Html Msg
viewOthers model others =
    let
        wishes =
            if model.isPhase2 then
                L.map (viewOther model) others
            else
                L.map (viewOtherPhase1 model) others

        title =
            div [ class "flex-h spread flex-baseline" ]
                [ h2 [] [ text "My Family" ]
                , button [ onClick (SwitchTo MyClaims) ] [ text "My Claims" ]
                ]
    in
        div [ class "others col-12 col-sm-6" ]
            (title :: wishes)


viewOtherPhase1 : Model -> ( String, UserData ) -> Html Msg
viewOtherPhase1 model ( userRef, { meta, presents } ) =
    div [ class "person section" ]
        [ div [] [ text <| meta.name ++ ": " ++ toString (Dict.size presents) ++ " suggestion(s)" ] ]


viewOther : Model -> ( String, UserData ) -> Html Msg
viewOther model ( userRef, { meta, presents } ) =
    let
        viewPresent presentRef present =
            case present.takenBy of
                Just id ->
                    if model.user.uid == id then
                        li [ class "present flex-h" ]
                            [ makeDescription present
                            , button
                                [ class "btn btn-success btn-sm"
                                , onClick <| Unclaim userRef presentRef
                                ]
                                [ text "Claimed" ]
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
                div [ class "person section" ]
                    [ h4 [] [ text meta.name ]
                    , ul [] ps
                    ]


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
viewNewIdeaForm { editor, isPhase2 } =
    let
        btn msg txt =
            button
                [ class "btn btn-primary"
                , onClick msg
                , disabled <| editor.description == ""
                ]
                [ text txt ]
    in
        div [ class "new-present section" ]
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
                    [ button [ class "btn btn-warning", onClick CancelEditor ] [ text "Cancel" ]
                    , case ( editor.uid, isPhase2 ) of
                        ( Just uid, False ) ->
                            button [ class "btn btn-danger", onClick (DeletePresent uid) ] [ text "Delete*" ]

                        _ ->
                            text ""
                    , button [ class "btn btn-success", onClick SubmitNewPresent, disabled <| editor.description == "" ] [ text "Save" ]
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


simpleHeader : Html msg
simpleHeader =
    header []
        [ div [ class "container flex-h" ]
            [ h4 [ class "truncate" ] [ text "Xmas 2017 coordination" ] ]
        ]


viewNavbar : Model -> Html Msg
viewNavbar model =
    header []
        [ div [ class "container" ]
            [ div [ class "flex-h spread" ]
                [ div []
                    [ i [ class "material-icons clickable", onClick ToggleSidebar ] [ text "menu" ] ]
                , div []
                    [ model.user.displayName
                        |> Maybe.map (text >> L.singleton >> strong [])
                        |> Maybe.withDefault (text "Xmas Present ideas")
                    , case model.user.photoURL of
                        Just photoURL ->
                            img [ src photoURL, class "avatar", alt "avatar" ] []

                        Nothing ->
                            text ""
                    ]
                ]
            ]
        ]


viewFooter : Html msg
viewFooter =
    footer []
        [ div [ class "container" ]
            [ div [ class "flex-h spread" ]
                [ a [ href "https://simonh1000.github.io/" ] [ text "Simon Hampton" ]
                , span [] [ text "Aug 2017" ]

                -- , a [ href "https://github.com/simonh1000/elm-firebase-demo" ] [ text "Code" ]
                ]
            ]
        ]



--


viewLogin : Model -> Html Msg
viewLogin model =
    div [ id "login", class "main container" ]
        [ div [ class "section google" ]
            [ h4 [] [ text "Quick Sign in (recommended)..." ]
            , img
                [ src "images/google_signin.png"
                , onClick GoogleSignin
                , alt "Click to sigin with Google"
                ]
                []
            ]
        , div [ class "section" ]
            [ h4 [] [ text "...Or with email address" ]
            , Html.form
                [ onSubmit Submit ]
                [ B.inputWithLabel UpdateEmail "Email" "email" model.email
                , B.passwordWithLabel UpdatePassword "Password" "password" model.password
                , button [ type_ "submit", class "btn btn-primary" ] [ text "Login" ]
                ]
            , button [ class "btn btn-default", onClick (SwitchTo Register) ]
                [ strong [] [ text "New?" ]
                , text " Register email address"
                ]
            ]
        ]


viewRegister : Model -> Html Msg
viewRegister model =
    let
        username =
            Maybe.withDefault "" model.user.displayName

        isDisabled =
            model.password == "" || model.password /= model.password2 || username == ""
    in
        div [ id "register", class "main container" ]
            [ h1 [] [ text "Register" ]
            , Html.form
                [ onSubmit SubmitRegistration, class "section" ]
                [ B.inputWithLabel UpdateUsername "Your Name" "name" username
                , B.inputWithLabel UpdateEmail "Email" "email" model.email
                , B.passwordWithLabel UpdatePassword "Password" "password" model.password
                , B.passwordWithLabel UpdatePassword2 "Retype Password" "password2" model.password2
                , div [ class "flex-h spread" ]
                    [ span [ onClick (SwitchTo Login) ] [ text "Login" ]
                    , button
                        [ type_ "submit"
                        , class "btn btn-primary"
                        , disabled isDisabled
                        ]
                        [ text "Register" ]
                    ]
                ]
            ]



--


isJust : Maybe a -> Bool
isJust =
    Maybe.map (\_ -> True) >> Maybe.withDefault False



-- CMDs


claim : String -> String -> String -> Cmd msg
claim uid otherRef presentRef =
    FB.set
        (makeSetPresentRef "takenBy" otherRef presentRef)
        (E.string uid)


purchase : String -> String -> Bool -> Cmd msg
purchase otherRef presentRef purchased =
    FB.set
        (makeSetPresentRef "purchased" otherRef presentRef)
        (E.bool purchased)


unclaim : String -> String -> Cmd msg
unclaim otherRef presentRef =
    FB.remove <| makeSetPresentRef "takenBy" otherRef presentRef


delete : Model -> String -> Cmd Msg
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


setMeta : String -> String -> E.Value -> Cmd msg
setMeta uid key val =
    FB.set ("/" ++ uid ++ "/meta/" ++ key) val


makeSetPresentRef : String -> String -> String -> String
makeSetPresentRef str otherRef presentRef =
    [ otherRef, "presents", presentRef, str ] |> String.join "/"
