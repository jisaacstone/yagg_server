alias Yagg.Board.Action.Ability
alias Yagg.Table.Player
alias Yagg.Board

defmodule Yagg.Unit do
  alias __MODULE__

  @enforce_keys [:attack, :defense, :name, :position]
  defstruct [:ability, :triggers, :visible | @enforce_keys]

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
    :visible => :all | :none | MapSet.t(:atom)
  }

  defimpl Poison.Encoder, for: Unit do
    def encode(%Unit{} = unit, opts) do
      Unit.encode(unit, :all) |> Poison.Encoder.Map.encode(opts)
    end
  end

  def encode(unit), do: encode(unit, unit.visible)

  def encode(_unit, :none), do: :nil
  def encode(unit, :all), do: encode_fields(unit, [:attack, :defense, :name, :player, :ability, :triggers], %{})
  def encode(unit, fields) when is_list(fields), do: encode_fields(unit, fields, %{})
  def encode(unit, fields), do: encode_fields(unit, MapSet.to_list(fields), %{})

  defp encode_fields(_unit, [], encoded), do: encoded
  defp encode_fields(unit, [field | fields], encoded) do
    encoded = Map.put_new(encoded, field, encode_field(unit, field))
    encode_fields(unit, fields, encoded)
  end

  defp encode_field(unit, :player), do: unit.position
  defp encode_field(unit, :ability), do: Ability.describe(unit.ability)
  defp encode_field(unit, :triggers), do: Enum.map(unit.triggers || %{}, fn({k, v}) -> {k, Ability.describe(v)} end) |> Enum.into(%{})
  defp encode_field(unit, field), do: Map.get(unit, field)

  def visible?(%{visible: :all}, _), do: :true
  def visible?(%{visible: :none}, _), do: :false
  def visible?(%{visible: v}, k), do: MapSet.member?(v, k)

  def make_visible(unit, fields) when is_list(fields), do: Enum.reduce(fields, unit, &make_visible(&2, &1))
  def make_visible(%{visible: :all} = unit, _), do: unit
  def make_visible(%{visible: :none} = unit, field), do: %{unit | visible: MapSet.new() |> MapSet.put(field)}
  def make_visible(unit, field), do: %{unit | visible: MapSet.put(unit.visible, field)}

  @spec new(Player.position, atom, non_neg_integer, non_neg_integer, :nil | module(), %{atom => module()}) :: t
  def new(position, name, attack, defense, ability \\ :nil, triggers \\ %{}, visible \\ MapSet.put(MapSet.new(), :player)) do
    %Unit{position: position, name: name, attack: attack, defense: defense, ability: ability, triggers: triggers, visible: visible}
  end
  def new(attrs) do
    struct(default(), attrs)
  end

  def default() do
    %Unit{
      attack: 0,
      defense: 0,
      name: :nil,
      position: :nil,
      ability: :nil,
      triggers: %{},
      visible: MapSet.new([:player]),
    }
  end

  def after_death(board, unit, coords, opts \\ []) do
    trigger_module(unit, :death).resolve(board, [{:coords, coords}, {:unit, unit} | opts])
  end
  def after_move(board, unit, from, to, opts \\ []) do
    trigger_module(unit, :move).resolve(board, [{:from, from}, {:to, to}, {:unit, unit} | opts])
  end

  def attack(board, unit, opponent, from, to), do: attack(board, unit, opponent, from, to, [])
  def attack(_, %{attack: :immobile}, _, _, _, _), do: {:err, :immobile}
  def attack(board, unit, opponent, from, to, opts) do
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
