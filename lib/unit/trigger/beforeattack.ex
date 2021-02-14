alias Yagg.Unit
alias Yagg.Board
alias Yagg.Event

defmodule Unit.Trigger.BeforeAttack do
  alias __MODULE__

  @enforce_keys [:from, :to, :unit, :opponent]
  defstruct @enforce_keys

  @type t :: %BeforeAttack{
    from: Board.Grid.coord,
    to: Board.Grid.coord,
    unit: Unit.t,
    opponent: Unit.t
  }

  @callback before_attack(Board.t, t) :: {Board.t, [Event.t]} | {:err, atom}

  defmacro __using__(opts) do
    quote do
      require Unit.Ability
      Unit.Ability.__using__(unquote(opts))
      @behaviour Unit.Trigger.BeforeAttack
      def resolve(board, opts) do
        {from, opts} = Keyword.pop(opts, :from)
        {to, opts} = Keyword.pop(opts, :to)
        {unit, opts} = Keyword.pop(opts, :unit)
        {opponent, opts} = Keyword.pop(opts, :opponent)
        data = %BeforeAttack{from: from, to: to, unit: unit, opponent: opponent}
        before_attack(board, data) |> Unit.Trigger.maybe_reveal(
          reveal?(), from, unit, :attack
        )
      end
    end
  end
end
