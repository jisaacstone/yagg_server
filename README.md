# YaggServer

Curl commands:

Table

create [returns table_id]:

    curl localhost:8000/table/new -H'Content-Type: application/json'

subscribe:

    curl 'localhost:8000/sse/table/ID/events?player=foo'


actions are found in `lib/table/actions/*.ex`

example: join:

    curl -i 'localhost:8000/table/ID/a/join' -H'Content-Type: application/json' -d'{"player": "laura"}'

Board

as soon as two players join a table the game starts.

board actions are int `lib/board/actions/*.ex`

example: move:

    curl -i 'localhost:8000/board/ID/action?player=mee' -H'Content-Type: application/json' -d'{"action": "move", "from_x": 3, "from_y": 3, "to_x": 3, "to_y": 2}'

State:

table state:

    curl -i 'localhost:8000/table/ID/state'

private state only a player knows

    curl -i 'localhost:8000/board/ID/player_state/PLAYER

FRONTEND:

ui is at `localhost:8000/fe/index.html`

go directly to game at `localhost:8000/fe/board.html?table=TABLE_ID&player=PLAYER`

EVENTS:

event spec is in`lib/event.ex` as well as modules for every specific event types

all sse events are send as the `game_event` type
all events have a stream of `:global`, `:north` or `:south` the filters the SSE stream
all events have the `kind` key that indicates their structure
