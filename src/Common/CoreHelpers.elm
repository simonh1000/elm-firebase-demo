module Common.CoreHelpers exposing (addCmd, addNone, addNothing, addSuffixIf, andAddCmd, andMap, attemptUpdateNth, bindMaybe_, changeValue, curry, debugALittle, decodeOnError, decodeSimpleCustomType, deleteFromArray, detectDuplicates, dictFilterMap, escapeString, exactMatch, exactMatchGeneral, exactMatchString, filterByList, flip, foldMaybe, foldRMaybe, foldRResult, foldResult, formatPluralIrregular, formatPluralIrregularAlt, formatPluralRegular, formatPluralRegularAlt, getNth, groupListBy, ifThenElse, indexedFoldl, insertIfMissing, insertNth, isJust, isNothing, listRemoveIndex, listSetIndex, mapKeys, mapMaybe, mapResult, mapThird, recoverResult, rejectByList, removeFromList, renameKey, rgxContains, rgxFind, rgxReplace, rgxSplitAtMost1, slice, stringFromBool, takeWhile, taskFromResult, uncurry, updateAndThen, updateArray, updateNth, updateNth_, updateWithParentMsg)

-- ONLY FOR THINGS THAT ARE TOTALLY UN-REMIX SPECIFIC

import Array exposing (Array)
import Dict exposing (Dict)
import Html.Attributes
import Json.Decode as Jdec exposing (Decoder)
import Json.Encode as Jenc
import List as L
import Regex
import Set exposing (Set)
import Task exposing (Task)
import Tuple


{-| Useful for logging a very long string (e.g. base 64 image)
-}
debugALittle : a -> a
debugALittle message =
    let
        _ =
            Debug.log "" (String.left 1000 <| Debug.toString message)
    in
    message



-- To prepare for 0.19


curry : (( a, b ) -> c) -> a -> b -> c
curry fn =
    \a b -> fn ( a, b )


uncurry : (a -> b -> c) -> ( a, b ) -> c
uncurry fn =
    \( a, b ) -> fn a b


flip : (a -> b -> c) -> b -> a -> c
flip function argB argA =
    function argA argB



-- Regex


rgxContains rgxString str =
    Regex.fromString rgxString
        |> Maybe.map (\rgx -> Regex.contains rgx str)
        |> Maybe.withDefault False


rgxFind rgxString tgt =
    Regex.fromString rgxString
        |> Maybe.map (\rgx -> Regex.find rgx tgt)
        |> Maybe.withDefault []


rgxReplace rgxString fn orig =
    Regex.fromString rgxString
        |> Maybe.map (\rgx -> Regex.replace rgx fn orig)
        |> Maybe.withDefault orig


rgxSplitAtMost1 rgxString orig =
    Regex.fromString rgxString
        |> Maybe.map (\rgx -> Regex.splitAtMost 1 rgx orig)
        |> Maybe.withDefault []



-- model/command chaining


ifThenElse : Bool -> a -> a -> a
ifThenElse cond yes no =
    if cond then
        yes

    else
        no


addSuffixIf bool suffix default =
    ifThenElse bool (default ++ suffix) default


{-| map the 3rd element of a tuple
-}
mapThird : (c -> d) -> ( a, b, c ) -> ( a, b, d )
mapThird fn ( a, b, c ) =
    ( a, b, fn c )


{-| (m, c) |> updateAndThen (produceModAndCmd m)
-}
updateAndThen : (m -> ( m, Cmd msg )) -> ( m, Cmd msg ) -> ( m, Cmd msg )
updateAndThen fn ( m1, c1 ) =
    let
        ( m2, c2 ) =
            fn m1
    in
    ( m2, Cmd.batch [ c1, c2 ] )


updateWithParentMsg : (msg -> m -> ( m, Cmd msg )) -> ( m, Maybe msg ) -> ( m, Cmd msg )
updateWithParentMsg update ( m, mbMsg ) =
    case mbMsg of
        Just msg ->
            update msg m

        Nothing ->
            ( m, Cmd.none )


{-| (m, c) |> andAddCmd (produceCmd m)
-}
andAddCmd : (m -> Cmd msg) -> ( m, Cmd msg ) -> ( m, Cmd msg )
andAddCmd fn ( m, c ) =
    ( m, Cmd.batch [ c, fn m ] )


{-| (m, c) |> addCmd c2
-}
addCmd : Cmd msg -> ( m, Cmd msg ) -> ( m, Cmd msg )
addCmd c ( m1, c1 ) =
    ( m1, Cmd.batch [ c, c1 ] )


{-| m |> addNone
-}
addNone : m -> ( m, Cmd msg )
addNone m =
    ( m, Cmd.none )


addNothing : ( m, cmd ) -> ( m, cmd, Maybe msg )
addNothing ( m, c ) =
    ( m, c, Nothing )



-- STRINGS


stringFromBool : Bool -> String
stringFromBool t =
    if t then
        "True"

    else
        "False"


escapeString : String -> String
escapeString =
    Jenc.string >> Jenc.encode 0


{-| Format plural for nouns which have an irregular plural

  - 0, child, children -> 0 children
  - 1, child, children -> 1 child
  - 10, child, children -> 10 children

-}
formatPluralIrregular : Int -> String -> String -> String
formatPluralIrregular nb singular plural =
    if nb == 0 then
        "0 " ++ plural

    else if nb == 1 then
        "1 " ++ singular

    else
        String.fromInt nb ++ " " ++ plural


{-| Format plural for nouns which have a regular plural (meaning the plural is the singular+ 's'

  - 0, day -> 0 days
  - 1, day -> 1 day
  - 10, day -> 10 day

-}
formatPluralRegular : Int -> String -> String
formatPluralRegular nb singular =
    formatPluralIrregular nb singular (singular ++ "s")


{-| Format plural for nouns which have an irregular plural

  - 0, child, children -> no children
  - 1, child, children -> one child
  - 10, child, children -> 10 children

-}
formatPluralIrregularAlt : Int -> String -> String -> String
formatPluralIrregularAlt nb singular plural =
    if nb == 0 then
        "no " ++ plural

    else if nb == 1 then
        "one " ++ singular

    else
        String.fromInt nb ++ " " ++ plural


{-| Format plural for nouns which have a regular plural (meaning the plural is the singular+ 's'

  - 0, day -> no days
  - 1, day -> one day
  - 10, day -> 10 day

-}
formatPluralRegularAlt : Int -> String -> String
formatPluralRegularAlt nb singular =
    formatPluralIrregularAlt nb singular (singular ++ "s")



-- Json Decoder


andMap : Decoder a -> Decoder (a -> b) -> Decoder b
andMap =
    Jdec.map2 (|>)


decodeOnError : (String -> Decoder a) -> Decoder a -> Decoder a
decodeOnError fn dec =
    Jdec.value
        |> Jdec.andThen
            (\val ->
                case Jdec.decodeValue dec val of
                    Ok res ->
                        Jdec.succeed res

                    Err err ->
                        fn <| Jdec.errorToString err
            )


decodeSimpleCustomType : String -> a -> Decoder a
decodeSimpleCustomType tgt tp =
    exactMatchString Jdec.string tgt (Jdec.succeed tp)


{-| Useful for decoding AST in that it allows you to check for the existence
of a string matching some constructor before proceeding further
-}
exactMatch : String -> String -> Decoder a -> Decoder a
exactMatch fieldname tgt dec =
    exactMatchString (Jdec.field fieldname Jdec.string) tgt dec


exactMatchString : Decoder String -> String -> Decoder a -> Decoder a
exactMatchString matchDecoder match dec =
    matchDecoder
        |> Jdec.andThen
            (\str ->
                if str == match then
                    dec

                else
                    Jdec.fail <| "[exactMatch2] tgt: " ++ match ++ " /= " ++ str
            )


exactMatchGeneral : Decoder a -> a -> Decoder b -> Decoder b
exactMatchGeneral matchDecoder match dec =
    matchDecoder
        |> Jdec.andThen
            (\val ->
                if val == match then
                    dec

                else
                    Jdec.fail <| "[exactMatch3] no match found"
            )



-- MAYBE


isJust : Maybe a -> Bool
isJust m =
    m /= Nothing


isNothing : Maybe a -> Bool
isNothing m =
    m == Nothing


foldMaybe : (a -> b -> Maybe b) -> Maybe b -> List a -> Maybe b
foldMaybe f bMaybe lst =
    L.foldl (\a acc -> acc |> Maybe.andThen (f a)) bMaybe lst


foldRMaybe : (a -> b -> Maybe b) -> Maybe b -> List a -> Maybe b
foldRMaybe f bMaybe lst =
    L.foldr (\a acc -> acc |> Maybe.andThen (f a)) bMaybe lst


mapMaybe : (a -> Maybe c) -> List a -> Maybe (List c)
mapMaybe fn lst =
    let
        go : a -> List c -> Maybe (List c)
        go item acc =
            Maybe.map (\item_ -> item_ :: acc) (fn item)
    in
    foldRMaybe go (Just []) lst



-- RESULT


foldResult : (a -> b -> Result e b) -> Result e b -> List a -> Result e b
foldResult f bResult lst =
    L.foldl (\a acc -> acc |> Result.andThen (f a)) bResult lst


foldRResult : (a -> b -> Result e b) -> Result e b -> List a -> Result e b
foldRResult f bResult lst =
    L.foldr (\a acc -> acc |> Result.andThen (f a)) bResult lst


mapResult : (a -> Result b c) -> List a -> Result b (List c)
mapResult fn lst =
    let
        go : a -> List c -> Result b (List c)
        go item acc =
            Result.map (\item_ -> item_ :: acc) (fn item)
    in
    foldRResult go (Ok []) lst


recoverResult : (err -> a) -> Result err a -> a
recoverResult fn res =
    case res of
        Ok a ->
            a

        Err err ->
            fn err


taskFromResult : Result x a -> Task x a
taskFromResult res =
    case res of
        Ok a ->
            Task.succeed a

        Err x ->
            Task.fail x



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
    L.filter (not << flip L.member tgts) lst


listSetIndex : Int -> a -> List a -> List a
listSetIndex idx a lst =
    List.take idx lst ++ a :: List.drop (idx + 1) lst


getNth : Int -> List a -> Maybe a
getNth idx lst =
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


attemptUpdateNth : (a -> Maybe a) -> Int -> List a -> Maybe (List a)
attemptUpdateNth fn idx lst =
    case L.drop idx lst of
        hd :: tl ->
            case fn hd of
                Just hd_ ->
                    Just <| L.take idx lst ++ hd_ :: tl

                Nothing ->
                    Nothing

        [] ->
            Nothing


updateNth_ : (a -> List a) -> Int -> List a -> List a
updateNth_ fn idx lst =
    case L.drop idx lst of
        hd :: tl ->
            L.take idx lst ++ fn hd ++ tl

        [] ->
            lst


{-| Inserts at index, pushing subsequent elements back
When index > Length of lst then append to end
-}
insertNth : Int -> a -> List a -> List a
insertNth idx a lst =
    case L.drop idx lst of
        [] ->
            lst ++ [ a ]

        tl ->
            L.take idx lst ++ (a :: tl)


{-| return list of duplicate items in a list
`["a", "a", "b", "c", "d", "d", "d"] -> ["a", "d"]`
-}
detectDuplicates : List comparable -> List comparable
detectDuplicates lst =
    lst
        |> groupListBy identity
        |> List.filter (\l -> List.length l > 1)
        |> List.filterMap List.head


groupListBy : (a -> comparable) -> List a -> List (List a)
groupListBy fn =
    let
        go item acc =
            let
                key =
                    fn item

                newItemAcc =
                    case Dict.get key acc of
                        Just accItem ->
                            item :: accItem

                        Nothing ->
                            [ item ]
            in
            Dict.insert key newItemAcc acc
    in
    L.foldr go Dict.empty >> Dict.values


takeWhile : (a -> Bool) -> List a -> List a
takeWhile predicate list =
    case list of
        [] ->
            []

        x :: xs ->
            if predicate x then
                x :: takeWhile predicate xs

            else
                []



-- swap : Int -> Int -> List a -> List a
-- swap idx1 idx2 lst =
--     let
--         ln =
--             L.length lst
--
--         outBounds q =
--             q < 0 || q > (ln - 1)
--     in
--         if outBounds idx1 || outBounds idx2 then
--             lst
--         else if idx1 > idx2 then
--             swap idx2 idx1 lst
--         else
--             -- (idx1 < idx2)
--             let
--                 p1 =
--                     L.take idx1 lst
--
--                 p2 =
--                     lst |> L.drop idx1 |> L.take 2
--
--                 p3 =
--                     L.drop (idx1 + 2) lst
--             in
--                 p1 ++ L.reverse p2 ++ p3
--
-- DICT


insertIfMissing : comparable -> a -> Dict comparable a -> Dict comparable a
insertIfMissing key val dict =
    case Dict.get key dict of
        Just _ ->
            dict

        Nothing ->
            Dict.insert key val dict


{-| Gets smaller dict from a larger one
-}
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


{-| Removes a list of keys from a Dict
-}
rejectByList : List comparable -> Dict comparable a -> Dict comparable a
rejectByList lst dict =
    L.foldl Dict.remove dict lst


mapKeys : (comparable -> comparable1) -> Dict comparable b -> Dict comparable1 b
mapKeys fn =
    Dict.toList >> L.map (\( k, v ) -> ( fn k, v )) >> Dict.fromList


renameKey : comparable -> comparable -> Dict comparable b -> Dict comparable b
renameKey oldKey newKey dict =
    dict |> Dict.get oldKey |> Maybe.map (\bd -> Dict.insert newKey bd dict) |> Maybe.withDefault dict


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



-- Array


updateArray : Int -> (a -> a) -> Array a -> Array a
updateArray idx fn arr =
    arr
        |> Array.get idx
        |> Maybe.map (fn >> flip (Array.set idx) arr)
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



--
-- bind : (m -> ( m, Cmd b )) -> ( m, Cmd b ) -> ( m, Cmd b )
-- bind update ( m1, c1 ) =
--     let
--         ( m2, c2 ) =
--             update m1
--     in
--         ( m2, Cmd.batch [ c1, c2 ] )
--
--


bindMaybe_ : (a -> b -> ( b, Cmd msg )) -> ( b, Maybe a ) -> ( b, Cmd msg )
bindMaybe_ update ( m, mbC ) =
    case mbC of
        Just c ->
            update c m

        Nothing ->
            ( m, Cmd.none )
