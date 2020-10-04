alias Yagg.Unit
alias Yagg.Event

defmodule Yagg.Jobfair do
  alias __MODULE__
  @enforce_keys [:army_size, :north, :south]
  defstruct @enforce_keys

  @type key :: non_neg_integer()
  @type fair :: %{
    choices: %{key => Unit.t},
    chosen: [key],
    ready: bool()
  }

  @type t :: %Jobfair{
    army_size: 1..20,
    north: fair(),
    south: fair()
  }

  @spec new(module) :: t
  def new(configuration) do
    %Jobfair{
      army_size: configuration.meta().army_size,
      north: %{
        choices: configuration.starting_units(:north) |> to_choicemap(),
        chosen: [],
        ready: false
      },
      south: %{
        choices: configuration.starting_units(:south) |> to_choicemap(),
        chosen: [],
        ready: false
      },
    }
  end

  @spec setup(t) :: {t, [Event.t]}
  def setup(jobfair) do
    e1 = Enum.map(jobfair.north.choices, &to_event(&1, :north))
    e2 = Enum.map(jobfair.south.choices, &to_event(&1, :south))
    {jobfair, [Event.GameStarted.new(army_size: jobfair.army_size) | e1 ++ e2]}
  end

  defp to_event({index, unit}, position) do
    Event.Candidate.new(position, index: index, unit: unit)
  end

  defp to_choicemap(units), do: to_choicemap(units, %{}, 0)
  defp to_choicemap([%{name: :monarch} | units], map, key), do: to_choicemap(units, map, key)
  defp to_choicemap([], map, _), do: map
  defp to_choicemap([unit | units], map, key) do
    to_choicemap(units, Map.put_new(map, key, unit), key + 1)
  end

  def choose(%{army_size: army_size}, _, indices) when length(indices) > army_size do
    {:err, :too_many}
  end
  def choose(%{army_size: army_size}, _, indices) when length(indices) < army_size do
    {:err, :too_few}
  end
  def choose(jobfair, position, indices) do
    if MapSet.size(MapSet.new(indices)) < length(indices) do
      {:err, :duplicates}
    else
      fair = Map.fetch!(jobfair, position)
      if Enum.all?(indices, &Map.has_key?(fair.choices, &1)) do
        {:ok, Map.put(jobfair, position, %{fair | chosen: indices, ready: :true})}
      else
        IO.inspect(indices: indices, choices: fair.choices, map: Enum.map(indices, fn(i) -> {i, Map.has_key?(fair.choices, i)} end))
        {:err, :badindex}
      end
    end
  end

  def chosen(jobfair, position) do
    fair = Map.get(jobfair, position)
    Enum.map(fair.chosen, fn(i) -> Map.fetch!(fair.choices, i) end)
  end

  def everybody_ready?(%{north: %{ready: :true}, south: %{ready: :true}}), do: :true
  def everybody_ready?(_), do: :false

  def units(jobfair, position) do
    fair = Map.get(jobfair, position)
    {:ok, fair}
  end
end
