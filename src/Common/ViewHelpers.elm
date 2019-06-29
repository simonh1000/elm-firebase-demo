module Common.ViewHelpers exposing (matIcon, simpleHeader)

import Html exposing (..)
import Html.Attributes exposing (..)


simpleHeader : Html msg
simpleHeader =
    header []
        [ div [ class "container flex-h" ]
            [ h4 [] [ text "Xmas 2019" ] ]
        ]


matIcon icon =
    --    i [ class <| "mdi mdi-" ++ icon ] []
    span [ class "iconify", attribute "data-icon" <| "mdi-" ++ icon ] []
