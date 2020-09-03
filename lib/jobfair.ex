alias Yagg.Unit

defmodule Yagg.Jobfair do
  alias __MODULE__
  @enforce_keys [:max, :min, :north, :south]
  defstruct @enforce_keys

  @type key :: non_neg_integer()
  @type fair :: %{
    choices: %{key => Unit.t},
    chosen: [key],
    ready: bool()
  }

  @type t :: %Jobfair{
    min: 0..20,
    max: 1..20,
    north: fair(),
    south: fair()
  }

  def new(configuration, max \\ 20, min \\ 0) do
    %Jobfair{
      max: max,
      min: min,
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

  defp to_choicemap(units), do: to_choicemap(units, %{}, 0)
  defp to_choicemap([unit | units], map, key) do
    to_choicemap(units, Map.put_new(map, key, unit), key + 1)
  end
  defp to_choicemap([], map, _), do: map

  def choose(%{max: max}, _, indices) when length(indices) > max do
    {:err, :too_many}
  end
  def choose(%{min: min}, _, indices) when length(indices) < min do
    {:err, :too_few}
  end
  def choose(jobfair, position, indices) do
    if MapSet.size(MapSet.new(indices)) < length(indices) do
      {:err, :duplicates}
    else
      fair = %{jobfair[position] | chosen: indices, ready: :true}
      {:ok, Map.put(jobfair, position, fair)}
    end
  end

  def everybody_ready?(%{north: %{ready: :true}, south: %{ready: :true}}), do: :true
  def everybody_ready?(_), do: :false
end
