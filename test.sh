table_id=$( curl localhost:8000/table/new -H'Content-Type: application/json' -d'{}' | cut -d'"' -f4 )
echo table $table_id
curl localhost:8000/table/${table_id}/a/join -H'Content-Type: application/json' -d'{"player": "test_player"}' -i
curl localhost:8000/table/${table_id}/a/ai -H'Content-Type: application/json' -d'{}' -i
state=$( curl localhost:8000/table/${table_id}/state )
echo $state | python3 -c'import sys, json; print(json.load(sys.stdin)["board"]["ready"])'
sleep 1
state=$( curl localhost:8000/table/${table_id}/state )
echo $state | python3 -c'import sys, json; print(json.load(sys.stdin)["board"]["ready"])'
curl localhost:8000/table/${table_id}/state
