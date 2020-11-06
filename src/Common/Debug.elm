module Debug exposing (..)


debugALittle : a -> a
debugALittle message =
    let
        _ =
            Debug.log "" (String.left 1000 <| Debug.toString message)
    in
    message
