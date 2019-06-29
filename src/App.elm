module App exposing (Flags, Msg(..), init, update, view)

import Bootstrap as B
import Common.CoreHelpers exposing (debugALittle)
import Dict exposing (Dict)
import Firebase.Firebase as FB exposing (FBCommand(..))
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Iso8601
import Json.Decode as Json exposing (Value)
import Json.Encode as E
import List as L
import Model as M exposing (..)



-- UPDATE


type Msg
    = SwitchTo Page
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
    | NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case message of
        -- Registration page
        SwitchTo page ->
            ( { model | page = page, showSettings = False }
            , Cmd.none
            )

        -- Main page
        ToggleSidebar ->
            ( { model | showSettings = not model.showSettings }, Cmd.none )

        ToggleNotifications notifications ->
            if notifications then
                ( { model | userMessage = "Attempting to subscribe" }, FB.sendToFirebase <| StartNotifications model.user.uid )

            else
                ( { model | userMessage = "Attempting to unsubscribe" }
                , FB.sendToFirebase <| StopNotifications model.user.uid
                )

        -- , FB.set model.user.uid "notifications" <|E.bool notifications )
        Signout ->
            ( blank
            , FB.signout
            )

        Claim otherRef presentRef ->
            ( model
            , claim model.user.uid otherRef presentRef
            )

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
            ( updateEditor (\ed -> { ed | description = description }) model
            , Cmd.none
            )

        UpdateNewPresentLink link ->
            ( updateEditor
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
            , Cmd.none
            )

        SubmitNewPresent ->
            ( { model | editor = blankPresent }
            , savePresent model
            )

        CancelEditor ->
            ( { model | editor = blankPresent }
            , Cmd.none
            )

        DeletePresent uid ->
            ( { model | editor = blankPresent }
            , delete model uid
            )

        -- New present form
        Expander ->
            ( { model | editorCollapsed = not model.editorCollapsed }, Cmd.none )

        EditPresent newPresent ->
            ( updateEditor (\_ -> newPresent) model
            , Cmd.none
            )

        NoOp ->
            ( model, Cmd.none )

        FBMsgHandler msg ->
            case msg.message of
                "authstate" ->
                    handleAuthChange msg.payload model

                "snapshot" ->
                    handleSnapshot msg.payload model

                "SubscriptionOk" ->
                    -- After Cloud Function returns successfully, update db to persist preference
                    ( { model | userMessage = "" }
                    , setMeta model.user.uid "notifications" <| E.bool True
                    )

                "UnsubscribeOk" ->
                    -- After Cloud Function returns successfully, update db to persist preference
                    ( { model | userMessage = "" }
                    , setMeta model.user.uid "notifications" <| E.bool False
                    )

                "CFError" ->
                    let
                        userMessage =
                            Json.decodeValue decoderError msg.payload
                                |> Result.withDefault model.userMessage
                    in
                    ( { model | userMessage = userMessage }
                    , Cmd.none
                    )

                "error" ->
                    let
                        userMessage =
                            Json.decodeValue decoderError msg.payload
                                |> Result.withDefault model.userMessage
                    in
                    ( { model | userMessage = userMessage }
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
                    ( model
                    , Cmd.none
                    )



-- Model update helpers


updateEditor : (Present -> Present) -> Model -> Model
updateEditor fn model =
    { model | editor = fn model.editor }


setDisplayName : String -> Model -> Model
setDisplayName displayName model =
    let
        user =
            model.user
    in
    { model | user = { user | displayName = Just displayName } }



-- ---------------------------------------
-- VIEW
-- ---------------------------------------


view : Model -> Html Msg
view model =
    let
        spinner =
            [ div [ class "loading" ]
                [ img [ src "spinner.svg" ] []
                , div [] [ text <| prettyPrint model.page ]
                ]
            ]
    in
    div [ class "app" ]
        [ if L.member model.page [ InitAuth, Subscribe, Login, Register ] then
            simpleHeader

          else
            viewNavbar model
        , div [ class <| "main " ++ String.toLower (Debug.toString model.page) ] <|
            case model.page of
                InitAuth ->
                    spinner

                Subscribe ->
                    spinner

                Login ->
                    [ viewLogin model ]

                Register ->
                    [ viewRegister model ]

                _ ->
                    -- Picker and Claims
                    [ model.xmas
                        |> Dict.get model.user.uid
                        |> Maybe.map (.meta >> .notifications)
                        |> Maybe.withDefault True
                        |> sidebar model
                    , viewPicker model
                    ]
        , div [ class "container warning" ] [ text model.userMessage ]
        , viewFooter
        ]


sidebar : Model -> Bool -> Html Msg
sidebar { userMessage, page, showSettings } notifications =
    div
        [ if showSettings then
            class "sidebar open"

          else
            class "sidebar"
        ]
        [ ul [ class "sidebar-inner" ]
            [ li [ class "sidebar-menu-item" ]
                [ div [ class "flex-h" ]
                    [ span [ class "left-element" ] [ switcher ToggleNotifications notifications ]
                    , text "Notifications"
                    ]
                , div [] [ text userMessage ]
                ]
            , if page == Picker then
                li [ onClick (SwitchTo MyClaims), class "sidebar-menu-item flex-h clickable" ]
                    [ span [ class "left-element" ] [ matIcon "card_giftcard" ]
                    , text "View my Claims"
                    ]

              else
                li [ onClick (SwitchTo Picker), class "sidebar-menu-item flex-h clickable" ]
                    [ span [ class "left-element" ] [ matIcon "people" ]
                    , text "View my Family"
                    ]
            , li [ class "sidebar-menu-item flex-h", onClick Signout ]
                [ span [ class "left-element" ] [ matIcon "power_settings_new" ], text "Signout" ]
            ]
        , div [ class "sidebar-remainder", onClick ToggleSidebar ] []
        ]


switcher : (Bool -> msg) -> Bool -> Html msg
switcher toggler isOn =
    if isOn then
        div [ class "switch on", onClick (toggler <| not isOn) ] []

    else
        div [ class "switch off", onClick (toggler <| not isOn) ] []



-- Main Page


viewPicker : Model -> Html Msg
viewPicker model =
    let
        ( mine, others ) =
            model.xmas
                |> Dict.toList
                |> L.partition (Tuple.first >> (==) model.user.uid)
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
            let
                claimsForPerson =
                    Dict.filter (\_ v -> v.takenBy == Just model.user.uid) other.presents
            in
            if Dict.isEmpty claimsForPerson then
                text ""

            else
                div [ class "person section" ]
                    [ h4 [] [ text other.meta.name ]
                    , claimsForPerson
                        |> Dict.map (mkItem oRef)
                        |> Dict.values
                        |> ul []
                    ]
    in
    div [ class "claims col-12 col-sm-6" ]
        [ h2 [] [ text "My Claims" ]
        , others
            |> L.map mkItemsForPerson
            |> div []
        ]


viewOthers : Model -> List ( String, UserData ) -> Html Msg
viewOthers model others =
    let
        wishes =
            if model.isPhase2 then
                L.map (viewOther model) others

            else
                L.map (viewOtherPhase1 model) others
    in
    div [ class "others col-12 col-sm-6" ]
        (h2 [] [ text "My Family" ] :: wishes)


viewOtherPhase1 : Model -> ( String, UserData ) -> Html Msg
viewOtherPhase1 _ ( _, { meta, presents } ) =
    div [ class "person section" ]
        [ div [] [ text <| meta.name ++ ": " ++ Debug.toString (Dict.size presents) ++ " suggestion(s)" ] ]


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

                        lst_ ->
                            lst_
                                |> L.map viewMyPresentIdea
                                |> ul []

                [] ->
                    text "Time to add you first idea!"

                _ ->
                    text <| "error" ++ Debug.toString lst

        cls =
            if model.page == MyClaims then
                -- for MyClaims, don't show LHS on small devices
                class "my-ideas d-none d-sm-block col-sm-6"

            else
                class "my-ideas col-sm-6"
    in
    div [ cls ]
        [ h2 []
            [ text "My Suggestions"

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
        , matIconMsg (EditPresent present) "mode_edit"
        ]


makeDescription : Present -> Html Msg
makeDescription { description, link } =
    case link of
        Just link_ ->
            a [ href link_, target "_blank" ] [ text description ]

        Nothing ->
            text description



--


matIcon : String -> Html msg
matIcon icon =
    i [ class "material-icons" ] [ text icon ]


matIconMsg : Msg -> String -> Html Msg
matIconMsg msg icon =
    i [ class "material-icons clickable", onClick msg, style "user-select" "none" ] [ text icon ]


viewNavbar : Model -> Html Msg
viewNavbar model =
    header []
        [ div [ class "container" ]
            [ div [ class "flex-h spread" ]
                [ div [ class "flex-h" ]
                    [ matIconMsg ToggleSidebar "menu"
                    , h4 [] [ text "Xmas 2017" ]
                    ]
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
                , a [ href "https://github.com/simonh1000/elm-firebase-demo" ] [ text "Code" ]
                ]
            ]
        ]



--
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
