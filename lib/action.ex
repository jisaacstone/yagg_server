defmodule Yagg.Action do
  @moduledoc """
  provides the resolve/1 and resolve/2 shortucts, and defies a stuct

  also defines the description/0 method. Requires @moduledoc to be already defined
  """
  @callback resolve(Dict.t, Yagg.Board.t, keyword()) :: {Yagg.Board.t, [Yagg.Event.t]} | {:err, term}
  @callback description() :: String.t

  def describe(:nil), do: :nil
  def describe(action) do
    name = Module.split(action) |> Enum.reverse() |> hd() |> String.downcase()
    %{name: name, args: action.__struct__(), description: action.description()}
  end

  defmacro __using__(opts) do
    struct = Keyword.get(opts, :keys, [])
    quote do
      @behaviour Yagg.Action

      @impl Yagg.Action
      def description(), do: @moduledoc
      @enforce_keys unquote(struct)
      defstruct @enforce_keys
      def resolve(board), do: resolve(%{}, board, [])
      def resolve(board, opts) when is_list(opts), do: resolve(%{}, board, opts)
    end
  end
end
