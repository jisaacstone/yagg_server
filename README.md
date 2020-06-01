# YaggServer

Curl commands:

Table

create [returns table_id]:

    curl localhost:8000/table/new -H'Content-Type: application/json'

subscribe:

    curl 'localhost:8000/sse/table/ID/events?player=foo'


actions are found in `lib/table/actions/*.ex`

example: join:

    curl -i 'localhost:8000/table/ID/action?player=mee' -H'Content-Type: application/json' -d'{"action": "join"}'

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

Very basic ui is at `localhost:8000/front/index.html`
