alias Yagg.Board
alias Yagg.Board.Configuration
alias Helper.TestConfig

defmodule Helper.Board do
  def testconfig(starting_u, terr, dimen) do
    contents = quote do
      def new() do
        %Configuration{
          name: :helper_testconfig,
          dimensions: unquote(Macro.escape(dimen)),
          units: %{north: starting_units(:north), south: starting_units(:south)},
          terrain: unquote(Macro.escape(terr)),
          initial_module: Yagg.Board,
        }
      end

      defp starting_units(position) do
        Enum.map(unquote(Macro.escape(starting_u)), fn(unit) -> %{unit | position: position} end)
      end
    end
    Module.create(DynTestConfig, contents, Macro.Env.location(__ENV__))
    DynTestConfig
  end

  def new_board(), do: new_board(TestConfig)
  def new_board(starting_u, terr, dimen) do
    config = testconfig(starting_u, terr, dimen)
    new_board(config)
  end
  def new_board(configuration) when is_atom(configuration) do
    new_board(configuration.new())
  end
  def new_board(%{} = config) do
    {board, _} = Board.new(config) |> Board.setup(config.units)
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

  def put_unit(board, position, unit_name, coord) do
    hand = board.hands[position]
    idx = Enum.find_value(
      hand,
      fn
        ({i, {%{name: ^unit_name}, _}}) -> i
        (_) -> :false
      end
    )
    {{unit, _}, hand} = Map.pop(hand, idx)
    grid = Map.put(board.grid, coord, unit)
    %{board | grid: grid, hands: Map.put(board.hands, position, hand)}
  end
end
