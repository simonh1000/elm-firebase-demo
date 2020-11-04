module Common.ViewHelpers exposing (..)

import Color
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


simpleHeader : Html msg
simpleHeader =
    header [ class "d-flex flex-row align-items-center justify-content-between" ] [ xmasHeader ]


xmasHeader : Html msg
xmasHeader =
    h4 [] [ text title ]


title =
    "KAT Secret Santa"


appGreen =
    Color.rgb255 41 167 69


mkTab : msg -> Bool -> ( Int -> Html msg, String ) -> Html msg
mkTab msg isActive ( icon, txt ) =
    div
        [ classList
            [ ( "tab clickable", True )
            , ( "active", isActive )
            , ( "narrow", txt == "" )
            ]
        , onClick msg
        ]
        [ icon 18
        , small [] [ text txt ]
        ]


badge : String -> String -> Html msg
badge cl t =
    span [ class <| "badge badge-" ++ cl ] [ text t ]


matIcon : String -> Html msg
matIcon icon =
    --    i [ class <| "mdi mdi-" ++ icon ] []
    span [ class "iconify", attribute "data-icon" <| "mdi-" ++ icon ] []



--matIconMsg : msg -> String -> Html msg
--matIconMsg msg icon =
--    i
--        [ class "iconify"
--        , attribute "data-icon" <| "mdi-" ++ icon
--        , onClick msg
--        , style "user-select" "none"
--        ]
--        [ text icon ]
