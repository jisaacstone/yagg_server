defmodule Yagg.Action do
  @moduledoc """
  provides the resolve/1 and resolve/2 shortucts, and defies a stuct
  """

  @callback resolve(Dict.t, Yagg.Board.t, List.t) :: {Yagg.Board.t, [Yagg.Event.t]} | {:err, term}

  defmacro __using__(opts) do
    quote do
      @behaviour Yagg.Action

      defstruct unquote(opts)
      def resolve(board), do: resolve(%{}, board, [])
      def resolve(board, opts) when is_list(opts), do: resolve(%{}, board, opts)
    end
  end
end
