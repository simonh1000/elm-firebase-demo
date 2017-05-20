module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json exposing (Value)
import Json.Encode as E
import Dict exposing (Dict)
import List as L
import Model as M exposing (..)
import Bootstrap as B
import Firebase as FB


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
    | SwitchToRegister
    | SubmitRegistration
      --
    | Signout
    | Claim String String
    | Unclaim String String
      -- Editor
    | UpdateNewPresent String
    | UpdateNewPresentLink String
    | SubmitNewPresent
    | CancelEditor
      -- My presents list
    | EditPresent Present
      -- Subscriptions
    | OnAuthStateChange Value
    | OnSnapshot Value


update : Msg -> Model -> ( Model, Cmd Msg )
update message model =
    case Debug.log "update" message of
        UpdateEmail email ->
            { model | email = email } ! []

        UpdatePassword password ->
            { model | password = password } ! []

        Submit ->
            model ! [ FB.signin model.email model.password ]

        -- Registration page
        SwitchToRegister ->
            { model | page = Register } ! []

        SubmitRegistration ->
            model ! [ FB.register model.email model.password ]

        UpdatePassword2 password2 ->
            { model | password2 = password2 } ! []

        UpdateUsername name ->
            { model | name = name } ! []

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

        EditPresent newPresent ->
            updateEditor (\_ -> newPresent) model ! []

        OnAuthStateChange val ->
            case Json.decodeValue decodeAuthState val |> Result.andThen identity of
                Ok user ->
                    ( { model | user = user, page = Picker }
                    , FB.subscribe "/"
                    )

                Err err ->
                    { model | user = blankUser, page = Login, userMessage = err } ! []

        OnSnapshot res ->
            case Json.decodeValue decoderXmas res of
                Ok xmas ->
                    case Dict.get model.user.uid xmas of
                        Just userData ->
                            { model | xmas = xmas, name = userData.meta.name } ! []

                        Nothing ->
                            { model | xmas = xmas } ! [ setMeta model.user.uid model.name ]

                Err err ->
                    { model | userMessage = err } ! []


updateEditor : (Present -> Present) -> Model -> Model
updateEditor fn model =
    let
        ed =
            model.editor
    in
        { model | editor = fn model.editor }



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
        , div [ class "warning" ] [ text model.userMessage ]
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
            [ header [ class "flex-h" ]
                [ div [ class "container flex-h spread" ]
                    [ strong [] [ text model.name ]
                    , button [ class "btn btn-outline-warning btn-sm", onClick Signout ] [ text "Signout" ]
                    ]
                ]
            , div [ class "container" ]
                [ div [ class "main row" ]
                    [ viewOthers model others
                    , viewMine model mine
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
                            , badge "text-success clickable" "Claimed"
                            ]
                    else
                        li [ class "present flex-h" ]
                            [ makeDescription present
                            , badge "text-warning" "Taken"
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


badge cl t =
    span [ class cl ] [ text t ]



--


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
        div [ class "mine col-sm-6 hidden-xs-down" ]
            [ h2 [] [ text "My suggestions" ]
            , viewSuggestionEditor model
            , mypresents
            ]


viewSuggestionEditor : Model -> Html Msg
viewSuggestionEditor { editor } =
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
            [ button
                [ class "btn btn-primary"
                , onClick SubmitNewPresent
                , disabled <| editor.description == ""
                ]
                [ text "Save" ]
            , button
                [ class "btn btn-primary"
                , onClick CancelEditor
                , disabled <| editor.description == ""
                ]
                [ text "Cancel" ]
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
        , Html.form
            [ onSubmit Submit ]
            [ B.inputWithLabel UpdateEmail "Email" "email" model.email
            , B.passwordWithLabel UpdatePassword "Password" "password" model.password
            , div [ class "flex-h spread" ]
                [ button [ type_ "submit", class "btn btn-primary" ] [ text "Login" ]
                , button [ type_ "button", class "btn btn-default", onClick SwitchToRegister ] [ text "New? Register yourself" ]
                ]
            ]
        ]


viewRegister : Model -> Html Msg
viewRegister model =
    div [ id "register" ]
        [ h1 [] [ text "Register" ]
        , Html.form
            [ onSubmit SubmitRegistration ]
            [ B.inputWithLabel UpdateUsername "Your Name" "name" model.name
            , B.inputWithLabel UpdateEmail "Email" "email" model.email
            , B.passwordWithLabel UpdatePassword "Password" "password" model.password
            , B.passwordWithLabel UpdatePassword2 "Retype Password" "password2" model.password2
            , button
                [ type_ "submit"
                , disabled <| model.password == "" || model.password /= model.password2
                , class "btn btn-primary"
                ]
                [ text "Login" ]
            ]
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
