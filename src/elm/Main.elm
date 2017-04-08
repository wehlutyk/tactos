module Main exposing (..)

import Html
import Html.Attributes as Attributes
import Mouse
import Ports
import Random
import Task
import Window


-- APP


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type alias Model =
    { cursor : Int
    , obstacle : Int
    , pointerLock : Maybe Bool
    , width : Int
    }


init : ( Model, Cmd Msg )
init =
    { cursor = -100
    , obstacle = -100
    , pointerLock = Just False
    , width = 0
    }
        ! [ Random.generate Obstacle (Random.int 0 100)
          , Task.perform WindowWidth Window.width
          ]



-- FIXME: use elm-css size value


objectSize : Int
objectSize =
    15



-- UPDATE


type Msg
    = Move Mouse.Movement
    | Obstacle Int
    | PointerLock (Maybe Bool)
    | WindowWidth Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Move movement ->
            case model.pointerLock of
                Just True ->
                    let
                        cursor =
                            (model.cursor + movement.x) % (model.width + objectSize)
                    in
                        { model | cursor = cursor } ! []

                Just False ->
                    model ! []

                Nothing ->
                    model ! []

        Obstacle vw ->
            { model | obstacle = vw } ! []

        PointerLock lock ->
            { model | pointerLock = lock } ! []

        WindowWidth width ->
            { model | width = width } ! []



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Mouse.moves Move
        , Ports.pointerLockChange (PointerLock << Just)
        , Ports.pointerLockError (always <| PointerLock Nothing)
        , Window.resizes (WindowWidth << .width)
        ]



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.div
        [ Attributes.id "container"
        , Attributes.classList [ ( "colliding", colliding model ) ]
        ]
        [ lockView model
        , lineView model
        ]


colliding : Model -> Bool
colliding model =
    let
        obstacle =
            round <| toFloat (model.obstacle * model.width) / 100
    in
        (obstacle - objectSize <= model.cursor) && (model.cursor <= obstacle + objectSize)


lockView : Model -> Html.Html Msg
lockView model =
    let
        text =
            case model.pointerLock of
                Just True ->
                    "Pointer locked — Press escape to release"

                Just False ->
                    "Click anywhere to start"

                Nothing ->
                    "Error locking pointer"
    in
        Html.header [] [ Html.h1 [] [ Html.text text ] ]


lineView : Model -> Html.Html Msg
lineView model =
    Html.main_ []
        [ Html.div
            [ Attributes.class "object"
            , Attributes.style [ ( "left", toString model.obstacle ++ "vw" ) ]
            ]
            []
        , Html.div
            [ Attributes.class "object"
            , Attributes.class "cursor"
            , Attributes.style [ ( "left", toString model.cursor ++ "px" ) ]
            ]
            []
        , Html.div [ Attributes.class "line" ] []
        ]
