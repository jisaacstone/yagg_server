alias Yagg.Unit

defmodule Unit.Ability.Immobile do
  @moduledoc """
  Cannot move
  """
  use Unit.Ability
  @impl Unit.Ability
  def resolve(_, _), do: {:err, :immobile}
end
