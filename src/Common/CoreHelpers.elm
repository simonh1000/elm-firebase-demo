module Common.CoreHelpers exposing (..)

import Array exposing (Array)
import Dict exposing (Dict)
import Json.Decode as Json exposing (Decoder)
import List as L
import Regex
import Set exposing (Set)



--------------------------------------------------------------------------------
-- misc
--------------------------------------------------------------------------------




{-| Useful for logging a very long string (e.g. base 64 image)
-}
debugALittle : a -> a
debugALittle message =
    let
        _ =
            Debug.log "" (String.left 1000 <| Debug.toString message)
    in
    message


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Json.map2 (|>)



-- MAYBE


isJust : Maybe a -> Bool
isJust m =
    m /= Nothing


isNothing : Maybe a -> Bool
isNothing m =
    m == Nothing



-- LISTS


indexedFoldl : (Int -> a -> b -> b) -> b -> List a -> b
indexedFoldl fn initialValue arr =
    let
        go : a -> ( Int, b ) -> ( Int, b )
        go a ( idx, acc ) =
            ( idx + 1, fn idx a acc )
    in
    L.foldl go ( 0, initialValue ) arr
        |> Tuple.second


slice : Int -> Int -> List a -> List a
slice offset howMany =
    L.drop offset >> L.take howMany


removeFromList : List a -> List a -> List a
removeFromList tgts lst =
    L.filter (not << (\a -> L.member a tgts)) lst


listSetIndex : Int -> a -> List a -> List a
listSetIndex idx a lst =
    List.take idx lst ++ a :: List.drop (idx + 1) lst


listGetIndex : Int -> List a -> Maybe a
listGetIndex idx lst =
    List.drop idx lst
        |> L.head


listRemoveIndex : Int -> List a -> List a
listRemoveIndex idx lst =
    List.take idx lst ++ List.drop (idx + 1) lst


changeValue : a -> a -> List a -> List a
changeValue tgt newVal =
    L.map
        (\currVal ->
            if currVal == tgt then
                newVal

            else
                currVal
        )


updateNth : (a -> a) -> Int -> List a -> List a
updateNth fn idx lst =
    case L.drop idx lst of
        hd :: tl ->
            L.take idx lst ++ fn hd :: tl

        [] ->
            lst


updateNth_ : (a -> List a) -> Int -> List a -> List a
updateNth_ fn idx lst =
    case L.drop idx lst of
        hd :: tl ->
            L.take idx lst ++ fn hd ++ tl

        [] ->
            lst


{-| When index > Length of lst then append to end
-}
insertNth : Int -> a -> List a -> List a
insertNth idx a lst =
    case L.drop idx lst of
        [] ->
            lst ++ [ a ]

        tl ->
            L.take idx lst ++ (a :: tl)


--moveFromTo : Int -> Int -> List a -> List a
--moveFromTo fromIdx toIdx lst =
--    let
--        getIndex idx =
--            listGetIndex idx lst |> Maybe.map L.singleton |> Maybe.withDefault []
--
--        -- fIdx < tIdx
--        destructure fIdx tIdx =
--            ( L.take fIdx lst
--            , getIndex fIdx
--            , lst
--                |> L.drop (fIdx + 1)
--                |> L.take (tIdx - (fIdx + 1))
--            , getIndex tIdx
--            , L.drop (tIdx + 1) lst
--            )
--    in
--    if fromIdx < toIdx then
--        let
--            ( bf, a1, bt, a2, af ) =
--                destructure fromIdx toIdx
--        in
--        bf ++ bt ++ a1 ++ a2 ++ af
--
--    else
--        let
--            ( bf, a1, bt, a2, af ) =
--                destructure toIdx fromIdx
--        in
--        bf ++ a2 ++ a1 ++ bt ++ af


unzip3 : List ( a, b, c ) -> ( List a, List b, List c )
unzip3 lst =
    let
        go ( a, b, c ) ( aa, bb, cc ) =
            ( a :: aa, b :: bb, c :: cc )
    in
    L.foldr go ( [], [], [] ) lst


-- DICT


filterByList : List comparable -> Dict comparable a -> Dict comparable a
filterByList lst dict =
    let
        folder fieldName acc =
            case Dict.get fieldName dict of
                Just field ->
                    Dict.insert fieldName field acc

                Nothing ->
                    acc
    in
    L.foldl folder Dict.empty lst


mapKeys : (comparable -> comparable1) -> Dict comparable b -> Dict comparable1 b
mapKeys fn =
    Dict.toList >> L.map (\( k, v ) -> ( fn k, v )) >> Dict.fromList


renameKey : comparable -> comparable -> Dict comparable b -> Dict comparable b
renameKey oldKey newKey dict =
    case Dict.get oldKey dict of
        Just oldVal ->
            dict
                |> Dict.remove oldKey
                |> Dict.insert newKey oldVal

        _ ->
            dict


dictFilterMap : (comparable -> a -> Maybe b) -> Dict comparable a -> Dict comparable b
dictFilterMap fn ds =
    let
        go key val acc =
            case fn key val of
                Just res ->
                    Dict.insert key res acc

                Nothing ->
                    acc
    in
    Dict.foldl go Dict.empty ds



--
--
-- upsert : comparable -> a -> Dict comparable a -> Dict comparable a
-- upsert key val d =
--     case Dict.get key d of
--         Just _ ->
--             Dict.insert key val d
--
--         Nothing ->
--             Dict.singleton key val
--
-- Array


updateArray : Int -> (a -> a) -> Array a -> Array a
updateArray idx fn arr =
    arr
        |> Array.get idx
        |> Maybe.map (fn >> (\a -> Array.set idx a arr))
        |> Maybe.withDefault arr


deleteFromArray : Int -> Array a -> Array a
deleteFromArray idx arr =
    let
        a1 =
            Array.slice 0 idx arr

        a2 =
            Array.slice (idx + 1) (Array.length arr) arr
    in
    Array.append a1 a2



bindMaybe_ : (a -> b -> ( b, Cmd msg )) -> ( b, Maybe a ) -> ( b, Cmd msg )
bindMaybe_ update ( m, maybeC ) =
    case maybeC of
        Just c ->
            update c m

        Nothing ->
            ( m, Cmd.none )



-- list function, taken from https://github.com/elm-community/list-extra


{-| Remove duplicate values, keeping the first instance of each element which appears more than once.
unique [0,1,1,0,1] == [0,1]
-}
unique : List comparable -> List comparable
unique list =
    uniqueHelp identity Set.empty list



uniqueHelp : (a -> comparable) -> Set comparable -> List a -> List a
uniqueHelp f existing remaining =
    case remaining of
        [] ->
            []

        first :: rest ->
            let
                computedFirst =
                    f first
            in
            if Set.member computedFirst existing then
                uniqueHelp f existing rest

            else
                first :: uniqueHelp f (Set.insert computedFirst existing) rest
