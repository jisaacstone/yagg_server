alias Yagg.Board.Configuration

defmodule Helper.Board do
  def testconfig(starting_u, terr, dimen) do
    contents = quote do
      def starting_units(position) do
        Enum.map(unquote(Macro.escape(starting_u)), fn(unit) -> %{unit | position: position} end)
      end
      def terrain(_), do: unquote(Macro.escape(terr))
      def dimensions(), do: unquote(Macro.escape(dimen))
    end
    Module.create(TestConfig, contents, Macro.Env.location(__ENV__))
    TestConfig
  end
  def new_board(starting_u, terr, dimen) do
    config = testconfig(starting_u, terr, dimen)
    new_board(config)
  end
  def new_board(config \\ Configuration.Alpha) do
    {board, _} = Yagg.Board.setup(Yagg.Board.new(config))
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
