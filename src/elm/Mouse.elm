effect module Mouse
    where { subscription = MySub }
    exposing
        ( Movement
        , movement
        , moves
        )

{-| This is an adaptation from the elm-lang/mouse library that handles
movementXY values.

This library lets you listen to global mouse events. This is useful
for a couple tricky scenarios including:
  - Detecting a "click" outside the current component.
  - Supporting drag-and-drop interactions.
# Mouse Movement
@docs Movement, movement
# Subscriptions
@docs moves
-}

import Dict
import Dom.LowLevel as Dom
import Json.Decode as Json
import Process
import Task exposing (Task)


-- MOVEMENTS


{-| The movement of the mouse.
-}
type alias Movement =
    { x : Int
    , y : Int
    }


{-| The decoder used to extract a `Movement` from a JavaScript mouse event.
-}
movement : Json.Decoder Movement
movement =
    Json.map2 Movement
        (Json.field "movementX" Json.int)
        (Json.field "movementY" Json.int)



-- MOUSE EVENTS


{-| Subscribe to mouse moves anywhere on screen. It is best to unsubscribe if
you do not need these events. Otherwise you will handle a bunch of events for
no benefit.
-}
moves : (Movement -> msg) -> Sub msg
moves tagger =
    subscription (MySub "mousemove" tagger)



-- SUBSCRIPTIONS


type MySub msg
    = MySub String (Movement -> msg)


subMap : (a -> b) -> MySub a -> MySub b
subMap func (MySub category tagger) =
    MySub category (tagger >> func)



-- EFFECT MANAGER STATE


type alias State msg =
    Dict.Dict String (Watcher msg)


type alias Watcher msg =
    { taggers : List (Movement -> msg)
    , pid : Process.Id
    }



-- CATEGORIZE SUBSCRIPTIONS


type alias SubDict msg =
    Dict.Dict String (List (Movement -> msg))


categorize : List (MySub msg) -> SubDict msg
categorize subs =
    categorizeHelp subs Dict.empty


categorizeHelp : List (MySub msg) -> SubDict msg -> SubDict msg
categorizeHelp subs subDict =
    case subs of
        [] ->
            subDict

        (MySub category tagger) :: rest ->
            categorizeHelp rest <|
                Dict.update category (categorizeHelpHelp tagger) subDict


categorizeHelpHelp : a -> Maybe (List a) -> Maybe (List a)
categorizeHelpHelp value maybeValues =
    case maybeValues of
        Nothing ->
            Just [ value ]

        Just values ->
            Just (value :: values)



-- EFFECT MANAGER


init : Task Never (State msg)
init =
    Task.succeed Dict.empty


type alias Msg =
    { category : String
    , movement : Movement
    }


(&>) : Task x a -> Task x b -> Task x b
(&>) t1 t2 =
    Task.andThen (\_ -> t2) t1


onEffects : Platform.Router msg Msg -> List (MySub msg) -> State msg -> Task Never (State msg)
onEffects router newSubs oldState =
    let
        leftStep category { pid } task =
            Process.kill pid &> task

        bothStep category { pid } taggers task =
            task
                |> Task.andThen (\state -> Task.succeed (Dict.insert category (Watcher taggers pid) state))

        rightStep category taggers task =
            let
                tracker =
                    Dom.onDocument category movement (Platform.sendToSelf router << Msg category)
            in
                task
                    |> Task.andThen
                        (\state ->
                            Process.spawn tracker
                                |> Task.andThen (\pid -> Task.succeed (Dict.insert category (Watcher taggers pid) state))
                        )
    in
        Dict.merge
            leftStep
            bothStep
            rightStep
            oldState
            (categorize newSubs)
            (Task.succeed Dict.empty)


onSelfMsg : Platform.Router msg Msg -> Msg -> State msg -> Task Never (State msg)
onSelfMsg router { category, movement } state =
    case Dict.get category state of
        Nothing ->
            Task.succeed state

        Just { taggers } ->
            let
                send tagger =
                    Platform.sendToApp router (tagger movement)
            in
                Task.sequence (List.map send taggers)
                    &> Task.succeed state
