alias Yagg.Unit.Ability
alias Yagg.Unit.Trigger
alias Yagg.Table.Player
alias Yagg.Board

defmodule Yagg.Unit do
  alias __MODULE__

  @enforce_keys [:attack, :defense, :name, :position]
  defstruct [:ability, :triggers, :visible, :monarch | @enforce_keys]

  @callback new(Player.position) :: t

  @type triggers :: %{optional(Trigger.type) => module()}

  @type t :: %Unit{
    :attack => 1 | 3 | 5 | 7 | 9,
    :defense => 0 | 2 | 4 | 6 | 8,
    :name => atom(),
    :monarch => boolean,
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


  @spec new(Player.position, atom, non_neg_integer, non_neg_integer, :nil | module(), %{atom => module()}) :: t
  def new(position, name, attack, defense, ability \\ :nil, triggers \\ %{}, visible \\ MapSet.put(MapSet.new(), :player)) do
    new(position: position, name: name, attack: attack, defense: defense, ability: ability, triggers: triggers, visible: visible)
  end
  def new(attrs) do
    # monarch is indicated by boolean or name
    monarch = Keyword.get(attrs, :monarch, Keyword.get(attrs, :name) == :monarch)
    struct(default(), [{:monarch, monarch} | attrs])
  end

  def default() do
    %Unit{
      monarch: :false,
      attack: 0,
      defense: 0,
      name: :nil,
      position: :nil,
      ability: :nil,
      triggers: %{},
      visible: MapSet.new([:player]),
    }
  end

  @spec encode(t) :: %{atom => any} | :nil
  def encode(unit), do: encode(unit, unit.visible)

  def encode(_unit, :none), do: :nil
  def encode(unit, :all), do: encode_fields(unit, [:attack, :defense, :name, :player, :ability, :triggers, :attributes], %{})
  def encode(unit, fields) when is_list(fields), do: encode_fields(unit, fields, %{})
  def encode(unit, fields), do: encode_fields(unit, MapSet.to_list(fields), %{})

  @spec visible?(t, atom) :: bool
  def visible?(%{visible: :all}, _), do: :true
  def visible?(%{visible: :none}, _), do: :false
  def visible?(%{visible: v}, k), do: MapSet.member?(v, k)

  @spec make_visible(t, atom | [atom]) :: t
  def make_visible(unit, fields) when is_list(fields), do: Enum.reduce(fields, unit, &make_visible(&2, &1))
  def make_visible(%{visible: :all} = unit, _), do: unit
  def make_visible(%{visible: :none} = unit, field), do: %{unit | visible: MapSet.new() |> MapSet.put(field)}
  def make_visible(unit, field), do: %{unit | visible: MapSet.put(unit.visible, field)}

  @spec set_trigger(t, atom, module) :: t
  def set_trigger(unit, type, ability) do
    %{unit | triggers: Map.put(unit.triggers, type, ability)}
  end

  @spec attack(Board.t, Unit.t, Unit.t, Board.Grid.coord, Board.Grid.coord) :: Board.resolved
  def attack(board, unit, opponent, from, to), do: attack(board, unit, opponent, from, to, [])
  def attack(_, %{attack: :immobile}, _, _, _, _), do: {:err, :immobile}
  def attack(board, unit, opponent, from, to, opts) do
    case Trigger.module(unit, :attack) do
      Ability.NOOP -> Board.do_battle(board, unit, opponent, from, to)
      module -> module.resolve(board, [{:from, from}, {:to, to}, {:opponent, opponent}, {:unit, unit} | opts])
    end
  end

  def encode_fields(_unit, [], encoded), do: encoded
  def encode_fields(unit, [field | fields], encoded) do
    encoded = Map.put_new(encoded, field, encode_field(unit, field))
    encode_fields(unit, fields, encoded)
  end

  def encode_field(unit, :player), do: unit.position
  def encode_field(unit, :ability), do: Ability.describe(unit.ability)
  def encode_field(unit, :triggers), do: Enum.map(unit.triggers || %{}, fn({k, v}) -> {k, Ability.describe(v)} end) |> Enum.into(%{})
  def encode_field(unit, :attributes) do
    Enum.reduce(
      [
        monarch: unit.monarch,
        invisible: unit.visible == :none, 
        immobile: unit.attack == :immobile
      ],
      [],
      fn
        ({k, :true}, attr) -> [k | attr]
        (_, attr) -> attr
      end
    )
  end
  def encode_field(unit, field), do: Map.get(unit, field)
end
