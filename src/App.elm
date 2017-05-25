module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json exposing (Value)
import Json.Encode as E
import Dict exposing (Dict)
import List as L
import Firebase.Firebase as FB
import Model as M exposing (..)
import Bootstrap as B


init : ( Model, Cmd Msg )
init =
    blank ! []



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
    | EditPresent Present
      -- Subscriptions
    | FBMsgHandler FB.FBMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case Debug.log "update" message of
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

        EditPresent newPresent ->
            updateEditor (\_ -> newPresent) model ! []

        FBMsgHandler { message, payload } ->
            case message of
                "authstate" ->
                    handleAuthChange payload model

                "snapshot" ->
                    handleSnapshot payload model

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
        Ok user ->
            ( { model | user = user, page = Picker }
            , FB.subscribe "/"
            )

        Err err ->
            { model | user = FB.init, page = Login, userMessage = err } ! []


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
            { model | userMessage = err } ! []



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ case model.page of
            Login ->
                viewLogin model

            Register ->
                viewRegister model

            Picker ->
                viewPicker model
        ]



--


viewPicker : Model -> Html Msg
viewPicker ({ user } as model) =
    let
        ( mine, others ) =
            model.xmas
                |> Dict.toList
                |> L.partition (Tuple.first >> ((==) user.uid))
    in
        div [ id "picker" ]
            [ viewHeader model
            , div [ class "container" ]
                [ div [ class "main row" ]
                    [ viewOthers model others
                    , viewMine model mine
                    ]
                ]
            ]


viewHeader : Model -> Html Msg
viewHeader model =
    header []
        [ div [ class "container" ]
            [ div [ class "flex-h spread" ]
                [ div []
                    [ case model.user.photoURL of
                        Just photoURL ->
                            img [ src photoURL, class "avatar" ] []

                        Nothing ->
                            text ""
                    , model.user.displayName
                        |> Maybe.map (text >> L.singleton >> strong [])
                        |> Maybe.withDefault (text "")
                    ]
                , button [ class "btn btn-outline-warning btn-sm", onClick Signout ] [ text "Signout" ]
                ]
            ]
        ]


viewOthers : Model -> List ( String, UserData ) -> Html Msg
viewOthers model others =
    div [ class "others col-12 col-sm-6" ] <|
        h2 [] [ text "Xmas wishes" ]
            :: L.map (viewOther model) others


viewOther : Model -> ( String, UserData ) -> Html Msg
viewOther model ( userRef, { meta, presents } ) =
    let
        viewPresent ( presentRef, present ) =
            case present.takenBy of
                Just id ->
                    if model.user.uid == id then
                        li [ onClick <| Unclaim userRef presentRef, class "present flex-h" ]
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
                |> Dict.toList
                |> L.map viewPresent
    in
        case ps of
            [] ->
                text ""

            _ ->
                div [ class "person other" ]
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
                    presents
                        |> Dict.values
                        |> L.map viewMyPresentIdea
                        |> ul []

                [] ->
                    text "time to add you first present"

                _ ->
                    text <| "error" ++ toString lst
    in
        div [ class "mine col-sm-6" ]
            [ h2 [] [ text "My suggestions" ]
            , viewSuggestionEditor model
            , mypresents
            ]


viewSuggestionEditor : Model -> Html Msg
viewSuggestionEditor { editor } =
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
            , B.inputWithLabel UpdateNewPresent "Description" "newpresent" editor.description
            , editor.link
                |> Maybe.withDefault ""
                |> B.inputWithLabel UpdateNewPresentLink "Link (optional)" "newpresentlink"
            , div [ class "flex-h spread" ]
                [ btn SubmitNewPresent "Save"
                , btn CancelEditor "Cancel"
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
            a
                [ href link_
                , target "_blank"
                ]
                [ text description ]

        Nothing ->
            text description



--


viewLogin model =
    div [ id "login" ]
        [ h1 [] [ text "Login" ]
        , div [ class "google" ]
            [ h4 [] [ text "Either sign in with Google" ]
            , img
                [ src "assets/btn_google_signin_light_normal_web.png"
                , onClick GoogleSignin
                ]
                []
            ]
        , div [ class "section" ]
            [ h4 [] [ text "Or sign in with other email address" ]
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
        , div [ class "warning" ] [ text model.userMessage ]
        ]


viewRegister : Model -> Html Msg
viewRegister model =
    div [ id "register" ]
        [ h1 [] [ text "Register" ]
        , Html.form
            [ onSubmit SubmitRegistration ]
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
        , div [ class "warning" ] [ text model.userMessage ]
        ]



-- CMDs


claim uid otherRef presentRef =
    FB.set
        (makeTakenByRef otherRef presentRef)
        (E.string uid)


unclaim otherRef presentRef =
    FB.remove <| makeTakenByRef otherRef presentRef


savePresent : Model -> Cmd Msg
savePresent model =
    case model.editor.uid of
        Just uid_ ->
            -- update existing present
            FB.set ("/" ++ model.user.uid ++ "/presents/" ++ uid_) (encodePresent model.editor)

        Nothing ->
            FB.push ("/" ++ model.user.uid ++ "/presents") (encodePresent model.editor)


setMeta uid name =
    FB.set (uid ++ "/meta") (E.object [ ( "name", E.string name ) ])


makeTakenByRef : String -> String -> String
makeTakenByRef otherRef presentRef =
    otherRef ++ "/presents/" ++ presentRef ++ "/takenBy"
