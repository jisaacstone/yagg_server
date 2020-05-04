defmodule Yagg.Event do
  alias __MODULE__
  defstruct [
    stream: :global,
    kind: :none,
    data: %{},
  ]

  def new(kind) do
    new(:global, kind, %{})
  end
  def new(kind, data) do
    new(:global, kind, data)
  end
  def new(stream, kind, data) do
    %Event{stream: stream, kind: kind, data: data}
  end
end
