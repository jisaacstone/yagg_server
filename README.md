# YaggServer

Curl commands:

Create Game:

    curl localhost:4000/game -H'Content-Type: application/json' -d'{"action": "create"}'

Subscribe/join:

    curl 'localhost:4000/game_events/GID?player=foo'

Start:

    curl localhost:4000/game -H'Content-Type: application/json' -d'{"action": "start", "game": "GID"}'
