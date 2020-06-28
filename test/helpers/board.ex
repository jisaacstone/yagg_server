alias Yagg.Board.Configuration

defmodule Helper.Board do
  def new_board(config \\ Configuration.Alpha) do
    {board, _} = Yagg.Board.setup(config)
    board
  end

  def set_board(features) do
    new_board() |> Map.put(:state, :battle) |> set_board(features)
  end
  def set_board(board, []), do: board
  def set_board(board, [{coord, feature} | features]) do
    grid = Map.put(board.grid, coord, feature)
    set_board(%{board | grid: grid}, features)
  end
end
