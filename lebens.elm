import Color exposing (..)
import Window
import Graphics.Collage exposing (..)
import Graphics.Element exposing (..)
import Keyboard
import Char
import Time exposing (..)
import List exposing (..)
import Set
import Random
import Html exposing (..)
import Html.Attributes exposing (..)


-- MODEL


type State = Select
           | Start
           | Play
           | Roundover


type alias Game =
    { players: List Player
    , state: State
    , gamearea: (Int, Int)
    , round: Int
    }


type alias Player =
    { id: Int
    , path: List (Position (Float, Float))
    , angle: Float
    , direction: Direction
    , alive: Bool
    , score: Int
    , color: Color
    , leftKey: Char.KeyCode
    , rightKey: Char.KeyCode
    , hole: Int
    }


type alias Input =
    { space: Bool
    , keys: Set.Set Char.KeyCode
    , delta: Time
    , gamearea: (Int, Int)
    , time: Time
    }


type Direction
    = Left
    | Right
    | Straight


type Position a = Visible a | Hidden a


maxAngleChange = 5
speed = 125
sidebarWidth = 250
sidebarBorderWidth = 5


player1 : Player
player1 =
    { id = 1
    , path = []
    , angle = 0
    , direction = Straight
    , alive = True
    , score = 0
    , color = rgb 254 221 3
    , leftKey = (Char.toCode 'Z')
    , rightKey = (Char.toCode 'X')
    , hole = 0
    }


player2 : Player
player2 =
    { player1 | id = 2
              , color = rgb 229 49 39
              , leftKey = 40
              , rightKey = 39
    }


player3 : Player
player3 =
    { player1 | id = 3
              , color = rgb 25 100 183
              , leftKey = (Char.toCode 'N')
              , rightKey = (Char.toCode 'M')
    }


defaultGame : Game
defaultGame =
    { players = [player1, player2, player3]
    , state = Start
    , gamearea = (0, 0)
    , round = 0
    }


-- UPDATE


update : Input -> Game -> Game
update {space, keys, delta, gamearea, time} ({players, state, round} as game) =
    let
        nextState =
            if space then
                case state of
                    Select -> Select
                    Start -> Play
                    Play -> Play
                    Roundover -> Play

            else
                if length (filter (\p -> p.alive) players) == 0 then
                   Roundover

                else
                    state

        round' =
            if state == Play && nextState == Roundover then
                round + 1

            else
                round

        players' =
            case nextState of
                Select -> players
                Start -> players
                Roundover -> players
                Play ->
                    if state == Start || state == Roundover then
                        map (initPlayer gamearea time) players

                    else
                        map (updatePlayer delta gamearea time players)
                        (mapInputs players keys)

    in
        { game | players = players'
               , gamearea = gamearea
               , state = nextState
               , round = round'
        }


initPlayer : (Int, Int) -> Time -> Player-> Player
initPlayer gamearea time player =
    let
        seed = (truncate (inMilliseconds time)) + player.id

    in
        { player | angle = randomAngle seed
                 , path = [Visible (randomPosition seed gamearea)]
                 , alive = True
        }


updatePlayer : Time -> (Int, Int) -> Time -> List Player -> Player -> Player
updatePlayer delta gamearea time allPlayers player =
    if not player.alive then
        player

    else
        let
            player' =
                move delta player

            playerPosition =
                Maybe.withDefault (Visible (0, 0)) (head player'.path)

            paths =
                foldl (\p acc -> append p.path acc) [] allPlayers

            paths' =
                filter (\p -> isVisible p) paths

            hs =
                any (hitSnake playerPosition) paths'

            hw =
                hitWall playerPosition gamearea

            winner =
                if length (filter (\p -> p.alive) allPlayers) < 2 then
                    True

                else
                    False

        in
            if hs || hw then
                { player' | alive = False }

            else if winner then
                { player' | score = player'.score + 1
                          , alive = False
                }

            else
                player'


move : Time -> Player -> Player
move delta player =
    let
        position =
            Maybe.withDefault (Visible (0, 0)) (head player.path)

        (x, y) =
            asXY position

        angle =
            case player.direction of
                Left -> player.angle + maxAngleChange
                Right -> player.angle + -maxAngleChange
                Straight -> player.angle

        vx =
            cos (angle * pi / 180)

        vy =
            sin (angle * pi / 180)

        nextX =
            x + vx * (delta * speed)

        nextY =
            y + vy * (delta * speed)

        visibility =
            if player.hole > 0 then
                Hidden

            else
                Visible

        hole =
            if player.hole < 0 then
                randomHole (truncate nextX)

            else
                player.hole - 1

    in
        { player | angle = angle
                 , path = visibility (nextX, nextY) :: player.path
                 , hole = hole
        }


randomHole : Int -> Int
randomHole seedInt =
    let
        seed =
            Random.initialSeed seedInt

        (n, _) =
            Random.generate (Random.int 0 150) seed

    in
        -- One chance out of 150 for n to be 1
        if n == 1 then
            fst (Random.generate (Random.int 5 10) seed)

        else
            0


randomAngle : Int -> Float
randomAngle seedInt =
    let
        seed =
            Random.initialSeed seedInt

        (n, _) =
            Random.generate (Random.int 0 360) seed

    in
        toFloat n


randomPosition : Int -> (Int, Int) -> (Float, Float)
randomPosition seedInt (w, h) =
    let
        seed =
            Random.initialSeed seedInt

        (x, _) =
            Random.generate (Random.int (w // 2) -(w // 2)) seed

        (y, _) =
            Random.generate (Random.int (h // 2) -(h // 2)) seed

    in
        (toFloat x, toFloat y)


-- are n and m within c of each other?
near : Float -> Float -> Float -> Bool
near n c m =
    m >= n-c && m <= n+c


hitSnake : Position (Float, Float) -> Position (Float, Float) -> Bool
hitSnake position1 position2 =
    let
        (x1, y1) =
            asXY position1

        (x2, y2) =
            asXY position2

    in
        near x1 1.9 x2
        && near y1 1.9 y2


hitWall : Position (Float, Float) -> (Int, Int) -> Bool
hitWall position (w, h) =
    let
        (w', h') =
            (toFloat w, toFloat h)

    in
        case position of
            Visible (x, y) ->
                if      x >= (w' / 2)  then True
                else if x <= -(w' / 2) then True
                else if y >= (h' / 2)  then True
                else if y <= -(h' / 2) then True
                else                       False

            Hidden _ ->
                False


-- VIEW


view : Game -> Html
view game =
    let
        (w, h) =
            game.gamearea

        (w', h') =
            (toFloat w, toFloat h)

        lines =
            (map renderPlayer game.players)

    in
        main' [ style [ ("position", "relative") ] ]
              [ fromElement (collage w h
                    (append
                        [ rect w' h'
                            |> filled (rgb 000 000 000)
                        ] (concat lines)
                    )
                )
              , sidebar game
              ]


renderPlayer : Player -> List Form
renderPlayer player =
    let
        coords =
            foldr toGroups [] player.path

        lineStyle =
            solid player.color

        visibleCoords =
            filter isGroupOfVisibles coords

        positions =
            map (\pts -> map asXY pts) visibleCoords

    in
        map (\pts -> traced lineStyle (path pts)) positions


sidebar game =
    div [ style [ ("position", "absolute")
                , ("right", "0")
                , ("top", "0")
                , ("width", (toString sidebarWidth) ++ "px")
                , ("height", "100%")
                , ("backgroundColor", "black")
                , ("borderLeft", (toString sidebarBorderWidth) ++ "px solid white")
                , ("color", "white")
                , ("textAlign", "center")
                ]
        ]
        [ h2 [] [(Html.text ((toString game.state) ++ "!"))]
        , h3 [] [(Html.text ("Round: " ++ toString game.round))]
        , ol [ style [ ("textAlign", "left"), ("color", "white") ] ] (map scoreboardPlayer (sortBy .score game.players |> reverse))
        , p  [ style [ ("color", "grey") ] ] [(Html.text "Press space to start a round")]
        ]


scoreboardPlayer {id, score, color} =
    li [ key (toString id), style [ ("color", (colorToString color)) ] ]
       [ Html.text ("Player " ++ (toString id) ++ " -- " ++ (toString score) ++ " wins") ]


colorToString c =
    let { red, green, blue } = toRgb c
    in
        "rgb(" ++ (toString red)
        ++ "," ++ (toString green)
        ++ "," ++ (toString blue)
        ++ ")"


--startScreen game = form
--roundoverScreen game = form
--gameoverScreen game = form


-- HELPERS


asXY : Position (Float, Float) -> (Float, Float)
asXY position =
    case position of
        Visible (x, y) -> (x, y)
        Hidden (x, y) -> (x, y)


isGroupOfVisibles : List (Position (Float, Float)) -> Bool
isGroupOfVisibles positions =
    case positions of
        [] -> False
        p :: _ -> isVisible p


isVisible : Position (Float, Float) -> Bool
isVisible position =
    case position of
        Visible _ -> True
        Hidden _ -> False


-- Usage:
--
-- foldr toGroups [] [Visible (0,1), Visible (0,2), Hidden (0,3), Hidden (0,4), Visible (0,5)]
-- ->
-- [[Visible (0,1), Visible (0,2)], [Hidden (0,3) ,Hidden (0,4)], [Visible (0,5)]]
toGroups : Position (Float, Float) -> List (List (Position (Float, Float))) -> List (List (Position (Float, Float)))
toGroups position acc =
    case acc of
        [] ->
            [position] :: acc

        x :: xs ->
            case x of
                [] ->
                    [position] :: acc

                y :: ys ->
                    if isVisible y && isVisible position then
                        (position :: x) :: xs

                    else
                        [position] :: acc


mapInputs : List Player -> Set.Set Char.KeyCode -> List Player
mapInputs players keys =
    let directions =
        map (toDirection keys) players

    in
        map2 (\p d -> { p | direction = d }) players directions


toDirection : Set.Set Char.KeyCode -> Player -> Direction
toDirection keys player =
    if Set.isEmpty keys then
        Straight

    else if Set.member player.leftKey keys
         && Set.member player.rightKey keys then
        Straight

    else if Set.member player.leftKey keys then
        Left

    else if Set.member player.rightKey keys then
        Right

    else
        Straight


-- SIGNALS


main : Signal Html
main =
    Signal.map view gameState


gameState : Signal Game
gameState =
    Signal.foldp update defaultGame (input defaultGame)


delta : Signal Time
delta =
    Signal.map inSeconds (fps 35)


input : Game -> Signal Input
input game =
    Signal.sampleOn delta <|
        Signal.map5 Input
            Keyboard.space
            Keyboard.keysDown
            delta
            (Signal.map (\(w, h) -> (w-sidebarWidth-sidebarBorderWidth, h)) Window.dimensions)
            (every millisecond)