module Auth exposing (AuthTab(..), Config, Model, Msg(..), blank, update, view, viewLogin, viewRegister)

import Color exposing (Color)
import Common.Bootstrap as B
import Common.ViewHelpers as ViewHelpers
import Firebase.Firebase as FB
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import List as L
import Material.Icons.Action as MAction
import Material.Icons.Social as MSocial
import Svg exposing (Svg)


type alias Model =
    { email : String
    , password : String
    , password2 : String
    , displayName : String
    , userMessage : Maybe String
    , tab : AuthTab
    }


blank : Model
blank =
    { email = ""
    , password = ""
    , password2 = ""
    , displayName = ""
    , userMessage = Nothing
    , tab = LoginTab
    }


type AuthTab
    = LoginTab
    | RegisterTab


{-| -}
stringFromTab : AuthTab -> ( Color -> Int -> Svg msg, String )
stringFromTab tab =
    case tab of
        LoginTab ->
            ( MAction.exit_to_app, "Login" )

        RegisterTab ->
            ( MSocial.person_add, "Register" )



--


type Msg
    = UpdateEmail String
    | UpdatePassword String
    | UpdatePassword2 String
    | UpdateDisplayName String
    | Submit
    | SubmitRegistration
    | GoogleSignin
    | SwitchTab AuthTab
    | OnLoginError String


type alias Config msg =
    { signin : String -> String -> msg
    , signinGoogle : msg
    , register : String -> String -> msg
    }


update : Msg -> Model -> ( Model, Cmd msg )
update message model =
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
            ( { model | tab = tab }, Cmd.none )

        SubmitRegistration ->
            ( { model | userMessage = Nothing }
            , FB.register model.email model.password
            )

        UpdatePassword2 password2 ->
            ( { model | password2 = password2 }, Cmd.none )

        UpdateDisplayName displayName ->
            ( { model | displayName = displayName }, Cmd.none )

        OnLoginError err ->
            ( { model | userMessage = Just err }, Cmd.none )


view : Model -> List (Html Msg)
view model =
    [ ViewHelpers.simpleHeader
    , div [ class "main" ] <|
        case model.tab of
            LoginTab ->
                viewLogin model

            RegisterTab ->
                viewRegister model
    , model.userMessage
        |> Maybe.map (\str -> div [ class "warning" ] [ text str ])
        |> Maybe.withDefault (text "")
    , [ LoginTab, RegisterTab ]
        |> L.map (\tab -> ViewHelpers.mkTab SwitchTab tab model.tab <| stringFromTab tab)
        |> footer [ class "tabs" ]
    ]


viewLogin : Model -> List (Html Msg)
viewLogin model =
    [ div [ class "section google" ]
        [ h4 [] [ text "Quick Sign in (recommended)..." ]
        , img
            [ src "images/google_signin.png"
            , onClick GoogleSignin
            , alt "Click to sign-in with Google"
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
        ]
    ]


viewRegister : Model -> List (Html Msg)
viewRegister model =
    let
        isDisabled =
            model.password == "" || model.password /= model.password2 || model.displayName == ""
    in
    [ div [ class "section" ]
        [ Html.form
            [ onSubmit SubmitRegistration ]
            [ B.inputWithLabel UpdateDisplayName "Name" "name" model.displayName
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
