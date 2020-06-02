alias Yagg.Event
alias Yagg.Table.Action
alias Yagg.Board.Configuration

defmodule Action.Rules do
  @enforce_keys [:configuration]
  defstruct @enforce_keys
  @behaviour Action

  @impl Action
  def resolve(%{configuration: config}, table, _) do
    case Configuration.all()[config] do
      :nil -> {:err, :unknown_config}
      conf_mod when is_atom(conf_mod) ->
        {
          %{table | configuration: conf_mod},
          Event.ConfigChange.new(config: config)
        }
    end
  end
end
