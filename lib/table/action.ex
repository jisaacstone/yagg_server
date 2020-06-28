alias Yagg.{Event, Board, Table}
alias Yagg.Table.Player
defmodule Yagg.Table.Action do
  @callback resolve(Dict.t, Table.t, Player.t | :notfound) :: {Table.t, [Event.t]} | {:err, atom()}

  @spec resolve(struct, Table.t, Player.t | :notfound) :: {Table.t, [Event.t]} | {:err, atom}
  def resolve(%{__struct__: mod} = action, table, player) do
    mod.resolve(action, table, player)
  end

  def initial_setup(table) do
    {board, events} = Board.setup(table.configuration)
    {%{table | board: board}, events}
  end
end
