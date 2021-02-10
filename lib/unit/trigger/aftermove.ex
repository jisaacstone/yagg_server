alias Yagg.Unit
alias Yagg.Board
alias Yagg.Event

defmodule Unit.Trigger.AfterMove do
  alias __MODULE__

  @enforce_keys [:from, :to, :unit]
  defstruct @enforce_keys

  @type t :: %AfterMove{
    from: Board.Grid.coord,
    to: Board.Grid.coord,
    unit: Unit.t
  }

  @callback after_move(Board.t, t) :: {Board.t, [Event.t]} | {:err, atom}

  defmacro __using__(opts) do
    quote do
      require Unit.Ability
      Unit.Ability.__using__(unquote(opts))
      @behaviour Unit.Trigger.AfterMove
      def resolve(board, opts) do
        {from, opts} = Keyword.pop!(opts, :from)
        {to, opts} = Keyword.pop!(opts, :to)
        {unit, opts} = Keyword.pop!(opts, :unit)
        data = %AfterMove{from: from, to: to, unit: unit}
        after_move(board, data)
      end
    end
  end
end
