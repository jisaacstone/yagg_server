alias Yagg.Board
alias Yagg.Board.Action
alias Yagg.Board.State.{Placement, Gameover}
alias Yagg.Event
alias Yagg.Unit

defmodule Action.Ready do
  @behaviour Action
  defstruct []

  @impl Action
  def resolve(_, %Board{state: %{ready: position}} = bord, position) do
    IO.inspect(bord: bord, pos: position)
    {:err, :already_ready}
  end
  def resolve(_act, %Board{state: %Placement{ready: :nil}} = board, position) do
    case units_assigned?(board, position) do
      :true -> {%{board | state: %Placement{ready: position}}, [Event.PlayerReady.new(player: position)]}
      :false -> {:err, :notready}
    end
  end
  def resolve(_act, %Board{state: %Placement{ready: _opponent}} = board, position) do
    case units_assigned?(board, position) do
      :true -> start_battle(board)
      :false -> {:err, :notready}
    end
  end
  def resolve(_, %Board{state: %Gameover{ready: :nil}} = board, position) do
    {
      %{board | state: %Gameover{ready: position}},
      [Event.PlayerReady.new(player: position)]
    }
  end
  def resolve(_act, %Board{state: %Gameover{ready: _opponent}} = board, _position) do
    initial = Board.Configuration.initial_board(board.configuration)
    initial.__struct__.setup(initial)
  end
  def resolve(_, _, _) do
    {:err, :badstate}
  end

  defp units_assigned?(%{hands: hands}, position) do
    # for not just check if the monarch has been placed
    !!Enum.find(hands[position], fn({_, {unit, coords}}) -> (unit.name == :monarch) and coords end)
  end

  defp start_battle(board) do
    try do
      board = board |> place_hand(:north) |> place_hand(:south)

      notifications = Enum.reduce(
        board.grid,
        [],
        fn
          ({{x, y}, %Unit{} = unit}, nfcns) ->
            [Event.UnitPlaced.new(x: x, y: y, player: unit.position) | nfcns]
          (_, nfcns) -> nfcns
        end
      )
      {%{board | state: :battle}, [Event.BattleStarted.new() | notifications]}
    catch
      err -> err
    end
  end

  defp place_hand(board, position) do
    {board, newhand} = Enum.reduce(
      board.hands[position],
      {board, %{}},
      fn
        ({i, {_, :nil} = v}, {board, hand}) ->
          {board, Map.put_new(hand, i, v)}
        ({_, {unit, {x, y}}}, {board, hand}) ->
          {Board.place!(board, unit, {x, y}), hand}
      end
    )
    %{board | hands: Map.put(board.hands, position, newhand)}
  end
end
