defmodule Yagg.Board.State do
  defmodule Placement do
    defstruct [:ready]
  end
  defmodule Gameover do
    defstruct [:ready, :winner]
  end

  @type t :: %Placement{} | %Gameover{} | :battle | :open
end
