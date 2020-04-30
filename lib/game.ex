defmodule YaggServer.Game do
  use GenServer
  alias __MODULE__  # so we can do %Game{} instead of %YaggServer.Game{}
  @enforce_keys [:state, :players]
  defstruct state: :open, players: []

  @type game_state :: :open | :started | :ended
  @type t :: %__MODULE__{
    state: game_state,
    players: List.t
  }

  def start_link(options) do
    GenServer.start_link(__MODULE__, [], options)
  end

  def init(:ok) do
    {:ok, %Game{state: :open, players: []}}
  end

  def handle_call({:join, player}, _from, %Game{state: :open} = game) do
    {:reply, :ok, %{game | players: [player | game.players]}}
  end
  def handle_call({:join, _player}, _from, game) do
    {:reply, {:err, :bad_state}, game}
  end

  def handle_call(:start, _from, %Game{players: []} = game) do
    {:reply, {:err, :no_players}, game}
  end
  def handle_call(:start, _from, %Game{state: :open} = game) do
    {:reply, :ok, %{game | state: :started}}
  end

  def handle_call(:end, _from, %Game{state: :started} = game) do
    {:reply, :ok, %{game | state: :ended}}
  end
  def handle_call(:end, _from, game) do
    {:reply, {:err, :bad_state}, game}
  end
end
