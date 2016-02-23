module Online where


import Input exposing (Input)
import Game exposing (..)


update : Input -> Game -> Game
update ({keys, delta, gamearea, time} as input) ({players, state, round} as game) =
    let
        state' =
            state
            -- updateState input game

        players' =
            players
            -- updatePlayers input game state'

        round' =
            round
            -- if state == Play && state' == Roundover then
            --     round + 1

            -- else
            --     round

    in
        { game | players = players'
               , gamearea = gamearea
               , state = state'
               , round = round'
        }