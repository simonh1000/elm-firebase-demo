module App exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Json.Decode as Json exposing (Value)
import Dict exposing (Dict)
import List as L
import Ports
import Model as M exposing (..)
import Bootstrap as B
import Firebase as FB


init : ( Model, Cmd Msg )
init =
    blank ! []



-- ( { blank | email = "sim@sim.be", password = "test11" }
-- , Cmd.none
-- )
-- UPDATE


type Msg
    = UpdateEmail String
    | UpdatePassword String
    | UpdatePassword2 String
    | UpdateUsername String
    | Submit
    | SwitchToRegister
    | SubmitRegistration
    | Signout
      --
    | Claim String String
    | Unclaim String String
      -- Editor
    | UpdateNewPresent String
    | UpdateNewPresentLink String
    | SubmitNewPresent
    | EditPresent Present
      --
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
            model ! [ FB.simpleMsg "signout" ]

        Claim otherRef presentRef ->
            model ! [ claim model.user.uid otherRef presentRef ]

        Unclaim otherRef presentRef ->
            model ! [ unclaim otherRef presentRef ]

        EditPresent newPresent ->
            updateEditor (\_ -> newPresent) model ! []

        UpdateNewPresent description ->
            updateEditor (\ed -> { ed | description = description }) model ! []

        UpdateNewPresentLink link ->
            updateEditor (\ed -> { ed | link = Just link }) model ! []

        SubmitNewPresent ->
            ( { model | editor = blankPresent }
            , savePresent model
            )

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
                            { model | xmas = xmas } ! [ FB.setMeta model.user.uid model.name ]

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
    div [ class "app container" ]
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
        div []
            [ header []
                [ text model.name
                , button [ class "btn btn-default", onClick Signout ] [ text "Signout" ]
                ]
            , h1 [] [ text "Choose presents" ]
            , div [ class "main row" ]
                [ viewOthers model others
                , viewMine model mine
                ]
            ]


viewOthers : Model -> List ( String, UserData ) -> Html Msg
viewOthers model others =
    others
        |> L.map (viewOther model)
        |> div [ class "others col-sm-6" ]


viewOther : Model -> ( String, UserData ) -> Html Msg
viewOther model ( userRef, { meta, presents } ) =
    let
        viewPresent ( presentRef, { description, takenBy } ) =
            case takenBy of
                Just id ->
                    if model.user.uid == id then
                        li [ onClick <| Unclaim userRef presentRef, class "present flex-h clickable" ]
                            [ text description
                            , badge "text-success" "Claimed"
                            ]
                    else
                        li [ class "present flex-h" ]
                            [ text description
                            , badge "text-warning" "Taken"
                            ]

                Nothing ->
                    li [ onClick <| Claim userRef presentRef, class "present flex-h clickable" ]
                        [ text description
                        ]

        ps =
            presents
                |> Dict.toList
                |> L.map viewPresent
                |> ul []
    in
        div [ class "person other" ]
            [ h3 [] [ text <| meta.name ]
            , ps
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
        div [ class "mine col-sm-6" ]
            [ h3 [] [ text "My suggestions" ]
            , viewSuggestionEditor model
            , mypresents
            ]


viewSuggestionEditor : Model -> Html Msg
viewSuggestionEditor { editor } =
    div [ class "new-present section" ]
        [ h3 []
            [ case editor.uid of
                Just _ ->
                    text "Editor"

                Nothing ->
                    text "New suggestion"
            ]
        , B.inputWithLabel UpdateNewPresent "newpresent" "Description" editor.description
        , editor.link
            |> Maybe.withDefault ""
            |> B.inputWithLabel UpdateNewPresentLink "newpresentlink" "Link"
        , div [ class "flex-h spread" ]
            [ button
                [ class "btn btn-primary"
                , onClick SubmitNewPresent
                ]
                [ text "Save" ]
            , button [ class "btn btn-primary", disabled True ] [ text "Cancel" ]
            ]
        ]


viewMyPresentIdea : Present -> Html Msg
viewMyPresentIdea present =
    li [ class "present flex-h spread" ]
        [ text present.description
        , span [ class "material-icons clickable", onClick (EditPresent present) ] [ text "mode_edit" ]
        ]



--


viewLogin model =
    div [ class "login flex-h" ]
        [ h1 [] [ text "Login" ]
        , Html.form
            [ onSubmit Submit ]
            [ B.inputWithLabel UpdateEmail "Email" "email" model.email
            , B.inputWithLabel UpdatePassword "Password" "password" model.password
            , div [ class "flex-h spread" ]
                [ button [ type_ "submit", class "btn btn-primary" ] [ text "Login" ]
                , button [ type_ "button", onClick SwitchToRegister, class "btn btn-default" ] [ text "new user" ]
                ]
            ]
        ]


viewRegister : Model -> Html Msg
viewRegister model =
    div [ class "register flex-h" ]
        [ h1 [] [ text "Register" ]
        , Html.form
            [ onSubmit SubmitRegistration ]
            [ B.inputWithLabel UpdateUsername "Your Name" "name" model.name
            , B.inputWithLabel UpdateEmail "Email" "email" model.email
            , B.inputWithLabel UpdatePassword "Password" "password" model.password
            , B.inputWithLabel UpdatePassword2 "Retype Password" "password2" model.password2
            , button
                [ type_ "submit"
                , disabled <| model.password == "" || model.password /= model.password2
                , class "btn btn-primary"
                ]
                [ text "Login" ]
            ]
        ]



--


claim uid otherRef presentRef =
    FB.set <| FB.makeClaimRef uid otherRef presentRef


unclaim otherRef presentRef =
    FB.remove <| FB.makeTakenByRef otherRef presentRef


savePresent : Model -> Cmd Msg
savePresent model =
    case model.editor.uid of
        Just uid_ ->
            -- update exisiting present
            FB.set_ ("/" ++ model.user.uid ++ "/presents/" ++ uid_) (encodePresent model.editor)

        Nothing ->
            FB.push_ ("/" ++ model.user.uid ++ "/presents") (encodePresent model.editor)
