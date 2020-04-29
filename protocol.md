# Events

{ "action": ACTION } | { "player_status": STATUS }

## action

    { "action": "move",
      "piece": ID,
      "to": [x, y] }

add powers, etc later?

## status

    { "player_status": "ready" }

when all players are ready game will start

    { "player_status": "quit" }

or is that an action?
