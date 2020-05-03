
POST `/game/create`

Create new game
Do later. Game ID ignored for now.

POST `/game/ID/action`

All game actions. Place, Move, etc

GET `/game/ID/state`

Get current game state

GET `/game/ID/events`

All events that happened in the game (do later)

GET `/sse/game/ID/events`

Subscribe to game events


Putting player in qargs probably easiest for now. Implement auth later
