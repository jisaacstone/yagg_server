defmodule Yagg.Action do
  defmacro __using__(opts) do
    quote do
      defstruct unquote(opts)
      def resolve(board), do: resolve(%{}, board, [])
      def resolve(board, opts) when is_list(opts), do: resolve(%{}, board, opts)
    end
  end
end
