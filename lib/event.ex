alias Yagg.Table.Player
alias Yagg.Board
alias Yagg.Unit

defmodule Yagg.Event do
  alias __MODULE__
  @enforce_keys [:stream, :kind, :data]
  defstruct @enforce_keys

  @type t :: %Event{
    stream: :global | Player.position(),
    kind: atom(),
    data: map(),
  }

  defimpl Poison.Encoder, for: Event do
    def encode(%Event{kind: kind, data: data}, options) do
      Poison.Encoder.Map.encode(Map.put_new(data, :event, kind), options)
    end
  end

  def new(kind) do
    new(:global, kind, %{})
  end
  def new(stream, kind) when is_atom(kind) do
    new(stream, kind, %{})
  end
  def new(kind, data) do
    new(:global, kind, data)
  end
  def new(stream, kind, data) when is_list(data) do
    %Event{stream: stream, kind: kind, data: Enum.into(data, %{})}
  end
  def new(stream, kind, data) do
    %Event{stream: stream, kind: kind, data: data}
  end

  defmodule Multi do
    @moduledoc """
    Multiple events
    """
    @spec new(
      events: [Event.t]
    ) :: Event.t
    def new(params) do
      Event.new(:global, :multi, params)
    end
  end

  defmodule UnitAssigned do
    @moduledoc """
    Placement Phase: a unit is assigned, from hand to square. never :global
    """

    @spec new(
      Player.position(),
      [ 
        index: term,
        x: 0..8,
        y: 0..8 
      ]) :: Event.t
 
    def new(position, params) do
      Event.new(position, :unit_assigned, params)
    end
  end

  defmodule UnitPlaced do
    @moduledoc """
    New unit placed on the board
    """

    @spec new([
        player: Player.position(),
        x: 0..8,
        y: 0..8
      ]) :: Event.t
    def new(params) do
      Event.new(:global, :unit_placed, params)
    end
  end

  defmodule UnitChanged do
    @moduledoc """
    Unit on board has attribute changed
    """
    @spec new(
      :global | Player.position(),
      [
        x: 0..8,
        y: 0..8,
        unit: Unit.t
      ]) :: Event.t
    def new(position, params) do
      Event.new(position, :unit_changed, params)
    end
  end

  defmodule NewUnit do
    @spec new(
      Player.position(),
      [
        x: 0..8,
        y: 0..8,
        unit: Unit.t
      ]) :: Event.t
    def new(position, params) do
      Event.new(position, :new_unit, params)
    end
  end

  defmodule Gameover do
    @spec new([winner: Player.position() | :draw]) :: Event.t
    def new(params) do
      Event.new(:global, :gameover, params)
    end
  end

  defmodule PlayerReady do
    @spec new([player: Player.position()]) :: Event.t
    def new(params) do
      Event.new(:global, :player_ready, params)
    end
  end

  defmodule GameStarted do
    def new(params \\ []) do
      Event.new(:global, :game_started, params)
    end
  end

  defmodule BattleStarted do
    def new() do
      Event.new(:global, :battle_started)
    end
  end

  defmodule AddToHand do
    @spec new(
      Player.position(),
      [
        index: term(),
        unit: Unit.t
      ]) :: Event.t
    def new(position, params) do
      Event.new(position, :add_to_hand, params)
    end
  end

  defmodule Candidate do
    @spec new(
      Player.position(),
      [
        index: term(),
        unit: Unit.t
      ]) :: Event.t
    def new(position, params) do
      Event.new(position, :candidate, params)
    end
  end

  defmodule UnitDied do
    @spec new([x: 0..8, y: 0..8]) :: Event.t
    def new(params) do
      Event.new(:global, :unit_died, params)
    end
  end

  defmodule Feature do
    @spec new([
      x: 0..8,
      y: 0..8,
      feture: term()
    ]) :: Event.t
    def new(params) do
      Event.new(:global, :feature, params)
    end
  end

  defmodule ThingMoved do
    @spec new([
      from: Board.Grid.coord,
      to: Board.Grid.coord | :offscreen | :hand
    ]) :: Event.t
    def new(params) do
      Event.new(:global, :thing_moved, params)
    end
    @spec new(
      Unit.t | Player.position,
      [
        from: Board.Grid.coord,
        to: Board.Grid.coord | :offscreen | :hand
      ]
    ) :: Event.t
    def new(%{visible: :none, position: position}, params) do
      Event.new(position, :thing_moved, params)
    end
    def new(_, params) do
      new(params)
    end
  end

  defmodule ThingGone do
    @spec new([
      x: 0..9,
      y: 0..9,
    ]) :: Event.t
    def new(params) do
      Event.new(:global, :thing_gone, params)
    end
  end

  defmodule Turn do
    @spec new([player: Player.position]) :: Event.t
    def new(params) do
      Event.new(:global, :turn, params)
    end
  end

  defmodule Timer do
    @spec new([
      player: Player.position | :all,
      timer: non_neg_integer
    ]) :: Event.t
    def new(params) do
      Event.new(:global, :timer, params)
    end
  end

  defmodule ConfigChange do
    @spec new([config: String.t]) :: Event.t
    def new(params) do
      Event.new(:global, :config_change, params)
    end
  end

  defmodule PlayerJoined do
    @spec new([
      player: Player.t,
      position: Player.position
    ]) :: Event.t
    def new(params) do
      Event.new(:global, :player_joined, params)
    end
  end

  defmodule AbilityUsed do
    @spec new(Keyword.t) :: Event.t
    def new(params) do
      Event.new(:global, :ability_used, params)
    end
    @spec new(Player.position, Keyword.t) :: Event.t
    def new(position, params) do
      Event.new(position, :ability_used, params)
    end
  end
end
