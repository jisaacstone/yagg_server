# YaggServer

Curl commands:

Create Game:

    curl localhost:4000/game/create -H'Content-Type: application/json'

Subscribe:

    curl 'localhost:4000/sse/game/GID/events?player=foo'

Join:

    curl -i 'localhost:4000/game/fii/action?player=mee' -H'Content-Type: application/json' -d'{"action": "join"}'
    curl -i 'localhost:4000/game/fii/action' -H'Content-Type: application/json' -d'{"action": "join", "player": "bar"}'

Game Id is ignored right now

State:

    curl -i 'localhost:4000/game/foo/state'
    {"state":"open","players":["mee","bar"]}

point a browser at the `index.html` for a barebones UI (under construction)
