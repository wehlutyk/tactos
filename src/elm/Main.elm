module Main exposing (..)

import Html
import Html.Attributes as Attributes
import Mouse
import Random


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
    }


init : ( Model, Cmd Msg )
init =
    ( { cursor = 0
      , obstacle = 0
      }
    , Random.generate Obstacle (Random.int 0 100)
    )



-- UPDATE


type Msg
    = Move Mouse.Position
    | Obstacle Int


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Move position ->
            { model | cursor = position.x } ! []

        Obstacle vw ->
            { model | obstacle = vw } ! []



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Mouse.moves Move



-- VIEW


view : Model -> Html.Html Msg
view model =
    Html.div [ Attributes.class "container" ]
        [ Html.div [] [ Html.text "Hello" ]
        , Html.div
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
