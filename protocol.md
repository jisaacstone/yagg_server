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

------

I couldnt help myself, just had to write some example data, I hope it makes sense:

--------------
COMMANDS
--------------
- include gameId
- include authenticated user (perhaps initially just use basic auth and ignore the password)
- POST http://server/games/{gameId}

create
{
}

join
{
}

placeUnit
{
  position: { x: 1, y: 2 },
  unit: { ... }   <-- having a map would allow all kinds of unit setups
}

moveUnit
{
  from: { x: 1, y: 2 },
  to: { x: 2, y: 2 },
  action: { ... }   <-- optional, having a map would allow all kinds of actions
}

--------------
STATE
--------------
- GET http://server/games/{gameId}

{
  board: {
    size: { x: 6, y: 6 }
  },
  playerCount: 2,
  players: [{
    id: ''
  }],
  units: [
    [{ position: { x: 1, y: 2 }, unit: { ... }}], <-- unit filtered if necessary
    [{ position: { x: 1, y: 2 }}]
  ]
}

----------
EVENTS
----------
- GET http://server/games/{gameId}/events

event stream would start with the current state

{
  event: 'gameCreated',
  {
    board: {
      size: { x: 6, y: 6 }
    },
    playerCount: 2,
    players: [{
      id: '',
      displayName: 'Jan',
    }]
  }
}

playerJoined
{
  playerNumber: 1,
  player: {
    id: ''
  }
}

unitPlaced
{
  unit: { ... }, <-- filtered
  position: { x: 1, y: 2 }
}

unitMoved
{
  from: { x: 1, y: 2 },
  to: { x: 2, y: 2 },
  action: { ... } <-- optional
}
