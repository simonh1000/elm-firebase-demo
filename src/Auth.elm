module Auth exposing (AuthTab(..), Config, Model, Msg(..), blank, update, view, viewLogin, viewRegister)

import Bootstrap as B
import Common.CoreHelpers exposing (addSuffixIf)
import Common.ViewHelpers as ViewHelpers
import Firebase.Firebase as FB
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List as L


type alias Model =
    { email : String
    , password : String
    , password2 : String
    , userMessage : Maybe String
    , tab : AuthTab
    }


blank : Model
blank =
    { email = ""
    , password = ""
    , password2 = ""
    , userMessage = Nothing
    , tab = LoginTab
    }


type AuthTab
    = LoginTab
    | RegisterTab


stringFromTab tab =
    case tab of
        LoginTab ->
            ( "cross", "Login" )

        RegisterTab ->
            ( "cross", "Register" )



--


type Msg
    = UpdateEmail String
    | UpdatePassword String
    | UpdatePassword2 String
    | UpdateUsername String
    | Submit
    | SubmitRegistration
    | GoogleSignin
    | SwitchTab AuthTab


type alias Config msg =
    { signin : String -> String -> msg
    , signinGoogle : msg
    , register : String -> String -> msg
    }


update : Config msg -> Msg -> Model -> ( Model, Cmd msg )
update config message model =
    case message of
        UpdateEmail email ->
            ( { model | email = email }
            , Cmd.none
            )

        UpdatePassword password ->
            ( { model | password = password }
            , Cmd.none
            )

        Submit ->
            ( { model | userMessage = Nothing }
            , FB.signin model.email model.password
            )

        GoogleSignin ->
            ( { model | userMessage = Nothing }
            , FB.signinGoogle
            )

        -- Registration page
        SwitchTab tab ->
            ( { model | tab = tab }
            , Cmd.none
            )

        SubmitRegistration ->
            ( { model | userMessage = Nothing }
            , FB.register model.email model.password
            )

        UpdatePassword2 password2 ->
            ( { model | password2 = password2 }
            , Cmd.none
            )

        UpdateUsername userName ->
            --            ( setDisplayName userName model
            ( model
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    div [ class "app" ]
        [ ViewHelpers.simpleHeader
        , case model.tab of
            LoginTab ->
                viewLogin model

            RegisterTab ->
                viewRegister model
        , [ LoginTab, RegisterTab ]
            |> L.map (\tab -> ViewHelpers.mkTab SwitchTab tab model.tab <| stringFromTab tab)
            |> footer [ class "tabs" ]
        ]


viewLogin : Model -> Html Msg
viewLogin model =
    div [ id "login", class "main" ]
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

            --            , button [ class "btn btn-default", onClick (SwitchTab RegisterTab) ]
            --                [ strong [] [ text "New?" ]
            --                , text " Register email address"
            --                ]
            ]
        ]


viewRegister : Model -> Html Msg
viewRegister model =
    let
        username =
            --            Maybe.withDefault "" model.user.displayName
            "something to get started with"

        isDisabled =
            model.password == "" || model.password /= model.password2 || username == ""
    in
    div [ id "register", class "main" ]
        [ div [ class "section" ]
            [ h1 [] [ text "Register" ]
            , Html.form
                [ onSubmit SubmitRegistration ]
                [ B.inputWithLabel UpdateUsername "Name" "name" username
                , B.inputWithLabel UpdateEmail "Email" "email" model.email
                , B.passwordWithLabel UpdatePassword "Password" "password" model.password
                , B.passwordWithLabel UpdatePassword2 "Retype Password" "password2" model.password2
                , button
                    [ type_ "submit"
                    , class "btn btn-primary"
                    , disabled isDisabled
                    ]
                    [ text "Register" ]
                ]
            ]
        ]
