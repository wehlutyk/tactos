port module Ports exposing (..)


port pointerLockChange : (Bool -> msg) -> Sub msg


port pointerLockError : (() -> msg) -> Sub msg
