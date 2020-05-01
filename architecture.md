Events:

Have an event channel per game?

We can treat opening up a channel as joining the game? 
Channels need to be tied to a player anyway, since data can be sensitive

Worry about auth later, just pass in player name or whatever as an ID for now

------

Game Flow:

GameCreate RPC call to create game, returns ID

subscribe to /events/game/GAME_ID to get updates. Send in ID as header

Game is in `Open` state

subscription counts as joining

when two players join game starts (we can build "player ready" signals later)

Game is in `Placeing` state

Both players place pieces, call DONE RPC

Game is in `Battle` state

game ends.

game can also end any time by a player disconnecting or forfit.

------

We can build out reconnect, persistance, fault tolerence, etc later.

Just keep game state in memory for prototype phase.

------

RPCs Needed:

* Create Game
* Place Piece
* Finished Placement
* Move Piece

See ideas in [protocol.md](/protocol.md)

build the rest later
