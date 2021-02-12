alias Yagg.Unit
alias Yagg.Board
alias Yagg.Event

defmodule Unit.Trigger.OnDeath do
  alias __MODULE__

  @enforce_keys [:coord, :unit]
  defstruct [:opponent | @enforce_keys]

  @type t :: %OnDeath{
    coord: Board.Grid.coord,
    unit: Unit.t,
    opponent: :nil | Unit.t
  }

  @callback on_death(Board.t, t) :: {Board.t, [Event.t]} | {:err, atom}

  defmacro __using__(opts) do
    quote do
      require Unit.Ability
      Unit.Ability.__using__(unquote(opts))
      @behaviour Unit.Trigger.OnDeath
      def resolve(board, opts) do
        {coord, opts} = Keyword.pop!(opts, :coords)
        {unit, opts} = Keyword.pop!(opts, :unit)
        {opponent, opts} = Keyword.pop(opts, :opponent)
        data = %OnDeath{coord: coord, unit: unit, opponent: opponent}
        on_death(board, data) |> Unit.Trigger.maybe_reveal(
          reveal?(), coord, unit, :death
        )
      end
    end
  end
end
