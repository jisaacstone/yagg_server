defmodule Yagg.AI.Weights do
  @type value :: %Yagg.Board.Action.Ability{} | %Yagg.Board.Action.Move{} | %Yagg.Board.Action.Place{}
  @type t :: {non_neg_integer, %{non_neg_integer => value}}

  @spec new() :: t
  def new(), do: {0, %{}}

  @spec add(t, non_neg_integer, value) :: t
  def add({total, mapping}, weight, action) do
    total = total + weight
    {total, Map.put(mapping, total, action)}
  end

  @spec random(t) :: {:err, atom} | {:ok, value}
  def random({0, _}), do: {:err, :no_choices}
  def random({max, mapping}) do
    choice_num = Enum.random(0..max)
    choice = match_key(choice_num, mapping)
    {:ok, choice}
  end

  defp match_key(k, m) do
    case m[k] do
      %{} = v -> v
      :nil -> match_key(k + 1, m)
    end
  end
end
