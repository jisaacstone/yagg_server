alias Yagg.Board

defmodule YaggTest.Board.Setup do
  use ExUnit.Case

  test 'setup' do
    {board, _events} = Board.setup()
    assert %{north: _, south: _} = board.hands
    assert [{{_x, _y}, _}|_] = Map.to_list(board.grid)
  end
end
