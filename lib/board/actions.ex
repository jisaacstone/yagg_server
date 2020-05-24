alias Yagg.Board
alias Yagg.Board.State.{Placement,Gameover}
alias Yagg.Unit
alias Yagg.Event

defmodule Board.Actions do
  defmodule Move do
    # naming things is hard
    @enforce_keys [:from_x, :from_y, :to_x, :to_y]
    defstruct @enforce_keys

    def resolve(move, %Board{state: :battle} = board, position) do
      case Board.move(board, position, {move.from_x, move.from_y}, {move.to_x, move.to_y}) do
        {:err, _} = err ->
          err
        {:ok, board, events} ->
          {board, events}
      end
    end
  end

  defmodule Place do
    @enforce_keys [:index, :x, :y]
    defstruct @enforce_keys

    def resolve(_, %Board{state: %Placement{ready: position}}, position) do
      {:err, :already_ready}
    end
    def resolve(act, %Board{state: %Placement{}} = board, position) do
      case Board.assign(board, position, act.index, {act.x, act.y}) do
        {:ok, board} -> 
          {
            board,
            [Event.new(position, :unit_assigned, %{index: act.index, x: act.x, y: act.y})]
          }
        err -> err
      end
    end

    def resolve(act, %Board{state: :battle} = board, position) do
      IO.inspect(%{hand: board.hands[position], index: act.index, position: position, hands: board.hands})
      {{unit, :nil}, hand} = Map.pop(board.hands[position], act.index)
      case Board.place(board, unit, {act.x, act.y}) do
        {:ok, board} ->
          {
            %{board | hands: %{board.hands | position => hand}},
            [
              Event.new(position, :unit_assigned, %{index: act.index, x: act.x, y: act.y}),
              Event.new(:global, :unit_placed, %{x: act.x, y: act.y, player: position}),
            ]
          }
        err -> err
      end
    end
  end

  defmodule Ready do
    defstruct []

    def resolve(_, %Board{state: %{ready: position}}, position) do
      {:err, :already_ready}
    end
    def resolve(_act, %Board{state: %Placement{ready: :nil}} = board, position) do
      case units_assigned?(board, position) do
        :true -> {%{board | state: %Placement{ready: position}}, [Event.new(:player_ready, %{player: position})]}
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
        {%{board | state: %Gameover{ready: position}}, [Event.new(:player_ready, %{player: position})]}
    end
    def resolve(_act, %Board{state: %Gameover{ready: _opponent}} = board, _position) do
      %{board | state: %Placement{}} |> Board.setup()
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
              [Event.new(:global, :unit_placed, %{x: x, y: y, player: unit.position}) | nfcns]
            (_, nfcns) -> nfcns
          end
        )
        {%{board | state: :battle}, [Event.new(:battle_started) | notifications]}
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

  def resolve(%{__struct__: mod} = action, board, position) do
    mod.resolve(action, board, position)
  end
end
