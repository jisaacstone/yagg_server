alias Yagg.Board.Action.Ability
alias Yagg.Table.Player
alias Yagg.Board

defmodule Yagg.Unit do
  alias __MODULE__
  @enforce_keys [:attack, :defense, :name, :position]
  defstruct [:ability, :triggers | @enforce_keys]

  @callback new(Player.position) :: t

  @type trigger :: :death | :move | :attack
  @type triggers :: %{optional(trigger) => module()}

  @type t :: %Unit{
    :attack => 1 | 3 | 5 | 7 | 9,
    :defense => 0 | 2 | 4 | 6 | 8,
    :name => atom(),
    :position => Player.position(),
    :ability => :nil | module() | {module(), Keyword.t},
    :triggers => triggers,
  }

  defimpl Poison.Encoder, for: Unit do
    def encode(%Unit{} = unit, opts) do
      %{
        attack: unit.attack,
        defense: unit.defense,
        name: unit.name,
        player: unit.position,
        ability: Ability.describe(unit.ability),
        triggers: Enum.map(unit.triggers || %{}, fn({k, v}) -> {k, Ability.describe(v)} end) |> Enum.into(%{})
      } |> Poison.Encoder.Map.encode(opts)
    end
  end

  @spec new(Player.position, atom, non_neg_integer, non_neg_integer, :nil | module(), %{atom => module()}) :: t 
  def new(position, name, attack, defense, ability \\ :nil, triggers \\ %{}) do
    %Unit{position: position, name: name, attack: attack, defense: defense, ability: ability, triggers: triggers}
  end

  def after_death(board, unit, coords, opts \\ []) do
    trigger_module(unit, :death).resolve(board, [{:coords, coords}, {:unit, unit} | opts])
  end
  def after_move(board, unit, from, to, opts \\ []) do
    trigger_module(unit, :move).resolve(board, [{:from, from}, {:to, to}, {:unit, unit} | opts])
  end
  def attack(board, unit, opponent, from, to, opts \\ []) do
    case trigger_module(unit, :attack) do
      Ability.NOOP -> Board.do_battle(board, unit, opponent, from, to)
      module -> module.resolve(board, [{:from, from}, {:to, to}, {:opponent, opponent}, {:unit, unit} | opts])
    end
  end

  @spec trigger_module(Unit.t, atom) :: module
  def trigger_module(%Unit{triggers: %{}} = unit, trigger) do
    unit.triggers[trigger] || Ability.NOOP
  end
  def trigger_module(_, _) do
    Ability.NOOP
  end

end
