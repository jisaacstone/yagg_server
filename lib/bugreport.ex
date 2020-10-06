defmodule Yagg.Bugreport do
  @moduledoc """
  Writes down possible errors and bugs to the "bugreports" file
  """
  def report(board, history, moves, report, meta) do
    {:ok, file} = File.open('bugreports', [:append])
    _ = IO.inspect(file, report, label: "report")
    _ = IO.inspect(file, DateTime.utc_now(), [])
    _ = IO.inspect(file, meta, pretty: :true)
    _ = IO.inspect(file, board, pretty: :true, width: :infinity)
    history
    |> Enum.take(moves)
    |> Enum.each(
      fn({board, action}) ->
        {
          IO.inspect(file, action, pretty: :true, width: :infinity),
          IO.inspect(file, board, pretty: :true, width: :infinity)
        }
      end
    )
  end
end
