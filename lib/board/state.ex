defmodule Yagg.Board.State do
  defmodule Placement do
    defstruct [:ready]
  end
  defmodule Gameover do
    defstruct [:ready]
  end

  @type t :: %Placement{} | %Gameover{} | :battle | :open
end
