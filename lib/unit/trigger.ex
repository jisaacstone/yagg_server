alias Yagg.Unit
alias Yagg.Event
alias Yagg.Board
alias Yagg.Board.Grid

defmodule Unit.Trigger do
  @type type :: :attack | :move | :death

  @spec reveal(Board.t, Grid.coord, Unit.t, type) :: {Board.t, [Event.t]}
  def reveal(board, {x, y}, unit, type) do
    {board, _} = Grid.update(board, {x, y}, fn(u) -> Unit.make_visible(u, [:triggers, :name]) end)
    event = Event.ShowAbility.new(
      x: x,
      y: y,
      type: type,
      reveal: %{
        name: Unit.encode_field(unit, :name),
        triggers: Unit.encode_field(unit, :triggers)
      }
    )
    {board, [event]}
  end

  @spec maybe_reveal(Board.resolved, boolean, Grid.coord, atom, type) :: Board.resolved
  def maybe_reveal({:err, reason}, _, _, _, _), do: {:err, reason}
  def maybe_reveal({board, []}, _, _, _, _), do: {board, []}
  def maybe_reveal({board, events}, :false, _, _, _), do: {board, events}
  def maybe_reveal({board, events}, :true, coord, name, type) do
    {board, [event]} = reveal(board, coord, name, type)
    {board, [event | events]}
  end

  @spec death(Board.t, Unit.t, Board.Grid.coord, Keyword.t) :: Board.resolved
  def death(board, unit, {x, y}, opts \\ []) do
    death_event = Event.UnitDied.new(x: x, y: y)
    case module(unit, :death).resolve(board, [{:coords, {x, y}}, {:unit, unit} | opts]) do
      {board, []} -> {board, [death_event]}
      # reveal event should be sent before death event so ui can hilight the trigger
      {board, [reveal_event | events]} -> {board, [reveal_event, death_event | events]}
    end
  end

  @spec after_move(Board.t, Unit.t, Board.Grid.coord, Board.Grid.coord, Keyword.t) :: Board.resolved
  def after_move(board, unit, from, to, opts \\ []) do
    module(unit, :move).resolve(board, [{:from, from}, {:to, to}, {:unit, unit} | opts])
  end

  @spec module(Unit.t, atom) :: module
  def module(%Unit{triggers: %{}} = unit, trigger) do
    unit.triggers[trigger] || Unit.Ability.NOOP
  end
  def module(_, _) do
    Unit.Ability.NOOP
  end
end
