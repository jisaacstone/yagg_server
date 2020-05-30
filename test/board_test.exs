alias Yagg.Board

defmodule YaggTest.Board.Setup do
  use ExUnit.Case

  test 'setup' do
    {board, _events} = Board.new() |> Board.setup()
    assert %{north: _, south: _} = board.hands
    assert %{{1, 2} => :water} = board.grid
  end
end