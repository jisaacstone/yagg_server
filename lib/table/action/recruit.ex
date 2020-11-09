alias Yagg.Jobfair
alias Yagg.Event
alias Yagg.Board
alias Yagg.Table
alias Yagg.Table.Player
alias Yagg.Unit

defmodule Yagg.Table.Action.Recruit do
  @enforce_keys [:units]
  defstruct @enforce_keys

  @spec resolve(%{units: [non_neg_integer]}, Table.t, Player.t) :: {:ok, Table.t} | {:err, atom}
  def resolve(%{units: indices}, table, %{id: id}) do
    recruit(clean(indices), table, Player.by_id(table, id))
  end

  defp recruit(indices, %{board: %Jobfair{} = jobfair} = table, {position, _player}) do
    case Jobfair.choose(jobfair, position, indices) do
      {:err, _} = err -> err
      {:ok, jobfair} ->
        table = %{table | board: jobfair}
        case Jobfair.everybody_ready?(jobfair) do
          true ->
            initial_setup(table)
          false ->
            {table, [Event.PlayerReady.new(player: position)]}
        end
    end
  end
  defp recruit(_, _, _) do
    {:err, :badstate}
  end

  defp clean(indices), do: clean([], indices)
  defp clean(cleaned, []), do: cleaned
  defp clean(cleaned, [dirty | rest]) when is_binary(dirty), do: clean([String.to_integer(dirty) | cleaned], rest)
  defp clean(cleaned, [clean | rest]) when is_integer(clean), do: clean([clean | cleaned], rest)

  defp initial_setup(table) do
    units = %{
      north: [Unit.Monarch.new(:north) | Jobfair.chosen(table.board, :north)],
      south: [Unit.Monarch.new(:south) | Jobfair.chosen(table.board, :south)]
    }
    {board, events} = Board.new(table.configuration) |> Board.setup(units)
    {%{table | board: board}, events}
  end
end
