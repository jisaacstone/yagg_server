# YaggServer

Curl commands:

Create Game:

    curl localhost:4000/game/create -H'Content-Type: application/json' -d'{}'

Subscribe:

    curl 'localhost:4000/sse/game/GID/events?player=foo'

Join:

    curl localhost:4000/game/action?player=foo -H'Content-Type: application/json' -d'{"action": "join"}'

Game Id is ignored right now
