alias Yagg.Board.Grid
alias Yagg.Board.Action

defmodule Yagg.AI.Weights do
  @type action :: %Yagg.Board.Action.Ability{} | %Yagg.Board.Action.Move{} | %Yagg.Board.Action.Place{}
  @type t(val) :: {non_neg_integer, %{non_neg_integer => val}}

  @spec new() :: t(any)
  def new(), do: {0, %{}}

  @spec add(t(action), non_neg_integer, action) :: t(action)
  @spec add(t(Grid.coord), non_neg_integer, Grid.coord) :: t(Grid.coord)
  @spec add(t(atom), non_neg_integer, atom) :: t(atom)
  def add({total, mapping}, weight, value) do
    total = total + weight
    {total, Map.put(mapping, total, value)}
  end

  @spec move(t(action), non_neg_integer, Grid.coord, Grid.coord) :: t(action)
  def move(weights, weight, {fx, fy}, {tx, ty}) do
    action = %Action.Move{from_x: fx, from_y: fy, to_x: tx, to_y: ty}
    add(weights, weight, action)
  end

  @spec ability(t(action), non_neg_integer, Grid.coord) :: t(action)
  def ability(weights, weight, {x, y}) do
    action = %Action.Ability{x: x, y: y}
    add(weights, weight, action)
  end

  @spec place(t(action), non_neg_integer, non_neg_integer, Grid.coord) :: t(action)
  def place(weights, weight, index, {x, y}) do
    action = %Action.Place{index: index, x: x, y: y}
    add(weights, weight, action)
  end

  @spec random(t(any)) :: {:err, :no_choices} | {:ok, action | Grid.coord | atom}
  def random({0, _}), do: {:err, :no_choices}
  def random({max, mapping}) do
    choice_num = Enum.random(0..max)
    choice = match_key(choice_num, mapping)
    {:ok, choice}
  end

  defp match_key(k, m) do
    case m[k] do
      :nil -> match_key(k + 1, m)
      v -> v
    end
  end
end
