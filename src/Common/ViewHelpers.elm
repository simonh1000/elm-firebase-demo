module Common.ViewHelpers exposing (..)

import Color
import Common.CoreHelpers exposing (addSuffixIf)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


simpleHeader : Html msg
simpleHeader =
    header [ class "flex-h flex-aligned flex-spread" ] [ xmasHeader ]


xmasHeader : Html msg
xmasHeader =
    h4 [] [ text title ]


title =
    "Xmas 2020"


mkTab : (c -> msg) -> c -> c -> ( Color.Color -> Int -> Html msg, String ) -> Html msg
mkTab msgConstructor tab selectedTab ( icon, txt ) =
    let
        green =
            Color.rgb255 41 167 69
    in
    div
        [ classList
            [ ( "tab clickable", True )
            , ( "active", tab == selectedTab )
            , ( "narrow", txt == "" )
            ]
        , onClick <| msgConstructor tab
        ]
        [ icon green 18
        , small [] [ text txt ]
        ]


badge : String -> String -> Html msg
badge cl t =
    span [ class <| "badge badge-" ++ cl ] [ text t ]



--matIcon : String -> Html msg
--matIcon icon =
--    --    i [ class <| "mdi mdi-" ++ icon ] []
--    span [ class "iconify", attribute "data-icon" <| "mdi-" ++ icon ] []
--matIconMsg : msg -> String -> Html msg
--matIconMsg msg icon =
--    i
--        [ class "iconify"
--        , attribute "data-icon" <| "mdi-" ++ icon
--        , onClick msg
--        , style "user-select" "none"
--        ]
--        [ text icon ]
