module Common.ViewHelpers exposing (matIcon, mkTab, simpleHeader)

import Common.CoreHelpers exposing (addSuffixIf)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)


simpleHeader : Html msg
simpleHeader =
    header []
        [ div [ class "container flex-h" ]
            [ h4 [] [ text "Xmas 2019" ] ]
        ]


matIcon icon =
    --    i [ class <| "mdi mdi-" ++ icon ] []
    span [ class "iconify", attribute "data-icon" <| "mdi-" ++ icon ] []


mkTab msgConstructor tab selectedTab ( icon, txt ) =
    div
        [ class <| addSuffixIf (tab == selectedTab) "tab" " active"
        , onClick <| msgConstructor tab
        ]
        [ matIcon icon
        , text txt
        ]
