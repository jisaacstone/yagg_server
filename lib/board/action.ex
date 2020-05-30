alias Yagg.Board
alias Yagg.Event

defmodule Board.Action do
  @callback resolve(Dict.t, Board.t, Yagg.Table.Player.position) :: {Board.t, [Event.t]} | {:err, atom}

  def resolve(%{__struct__: mod} = action, board, position) do
    mod.resolve(action, board, position)
  end
end
