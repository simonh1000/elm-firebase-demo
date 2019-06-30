module Common.ViewHelpers exposing (badge, matIcon, matIconMsg, mkTab, simpleHeader, switcher)

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


matIconMsg : msg -> String -> Html msg
matIconMsg msg icon =
    i
        [ class "iconify"
        , attribute "data-icon" <| "mdi-" ++ icon
        , onClick msg
        , style "user-select" "none"
        ]
        [ text icon ]


mkTab msgConstructor tab selectedTab ( icon, txt ) =
    div
        [ "tab"
            |> addSuffixIf (tab == selectedTab) " active"
            |> addSuffixIf (txt == "") " narrow"
            |> class
        , onClick <| msgConstructor tab
        ]
        [ matIcon icon
        , small [] [ text txt ]
        ]


badge : String -> String -> Html msg
badge cl t =
    span [ class <| "badge badge-" ++ cl ] [ text t ]


switcher : (Bool -> msg) -> Bool -> Html msg
switcher toggler isOn =
    if isOn then
        div [ class "switch on", onClick (toggler <| not isOn) ] []

    else
        div [ class "switch off", onClick (toggler <| not isOn) ] []
