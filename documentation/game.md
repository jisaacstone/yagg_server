# Game Architecture

## The Table

Game state is maintained by [table.ex](../lib/table.ex)
It is a `GenServer` supervised by `Yagg.TableSupervisor`.

Main calls to mutate state are `new`, `table_action` and `board_action`

Table actions have a scope of the entire table, board actions are scoped down to the board only.
Table actions are structs, the module of the struct is expected to implement [the Table.Action behavior](../lib/table/action.ex).
Likewise board actions are structs and the modules are expected to implement [the Board.Action behavior](../lib/board/action.ex).

## The Board

There are two "board implementations". [Board](../lib/board.ex) and [Jobfair](../lib/jobfair.ex).
Boards are expected to have a `new\1` and `setup\1` method to create the initial state, and a `units\2` and `Poison.Encoder` implementation. The `Poison.Encoder` implementation is used for fetching globally visible state, and `units\2` is used to fetch
state that is only visible to a single player

## Configurations

[Board.Configuration](../lib/board/configuration.ex) is a behavior. Currently the methods define the size of the board, the units a player starts with, the starting "board" (`Board` or `Jobfair`)
and the features (blocks and water) on the board.

I am not satisfied with how this works. For one thing, there is no set state. For example the `Board.Configuration.Random` returns a new value for `dimensions` each time `meta\1` is called.
This implicitly relies on `meta` only being called once, there is no type check or guarentee this will be the case in the future. Bugs would be easy to introduce.

Possibly a better interface would be a single method that returned a `Configuration` struct, and the struct would be stored in the table and board state, rather than the module name.

Thinking about adding other tuneables to configuration as well, for example on larger boards we may want to have the first three rows be placeable. TBD

## The Grid

The state of the units in battle is stored on a grid object. The type definition and methods for manipulating the grid are found in [Board.Grid](../lib/board/grid.ex)

The grid type is a map with `{y, y}` coordinate tuple keys and values of whatever is in the space. `:nil` indicates an empty square, but usually only squares with things in them are kept in the grid,
so lacking a key for the `{x, y}` is the preferred indication of an empty square.

This solution constrains our design in two ways.

First all metadata about a coordinate aside from its contents must be stored elsewhere, including weather a unit can be placed there or if it is a board edge, etc.
If we want to expand the gameplay for example by having squares that give a bonus to defense we may want to change this design.

Second the board is constrained to a square shape. An alternative design might be keeping all keys in the grid map, and any key not present is not part of gameplay, but any key present represents
a playable square. This would allow us to design more complex shaped playing areas more easily, and possibly even do a hexgrid implementation.
