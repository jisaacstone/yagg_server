alias Yagg.Board.Grid
import Helper.Board

defmodule YaggTest.Grid do
  use ExUnit.Case

  test "projectile" do
    board = set_board([
      {{2, 0}, %Yagg.Unit{ability: nil, attack: 5, defense: 4, monarch: false, name: :mediacreep, position: :south, triggers: %{move: Yagg.Unit.Mediacreep.Duplicate}}}, 
      {{2, 3}, %Yagg.Unit{ability: nil, attack: 1, defense: 0, monarch: false, name: :dogatron, position: :south, triggers: %{death: Yagg.Unit.Dogatron.Upgrade}}},
      {{2, 4}, %Yagg.Unit{ability: Yagg.Unit.Maycorn.Spark.Front, attack: 3, defense: 4, monarch: false, name: :maycorn, position: :north, triggers: %{death: Yagg.Unit.Maycorn.Spark.All}}}, 
    ])
    assert {{2, 3}, %{name: :dogatron}} = Grid.projectile(board, {2, 4}, :south)
  end
end
