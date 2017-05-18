module Bootstrap exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)


inputWithButton : (String -> msg) -> msg -> String -> Html msg
inputWithButton updater clicker val =
    div [ class "input-group" ]
        [ input
            [ class "form-control"
            , onInput updater
            , value val
            ]
            []
        , span
            [ class "input-group-btn" ]
            [ button
                [ class "btn btn-primary", onClick clicker ]
                [ text "Go!" ]
            ]
        ]


formGroup : (String -> msg) -> String -> String -> String -> Html msg
formGroup msg lab id_ val =
    div [ class "form-group" ]
        [ label [ for id_ ] [ text lab ]
        , input
            [ onInput msg, class "form-control", id id_, value val ]
            []
        ]
