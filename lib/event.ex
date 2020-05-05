defmodule Yagg.Event do
  alias __MODULE__
  defstruct [
    stream: :global,
    kind: :none,
    data: %{},
  ]
  defimpl Poison.Encoder, for: Event do
    def encode(%Event{kind: kind, data: data}, options) do
      Poison.Encoder.Map.encode(Map.put_new(data, :event, kind), options)
    end
  end

  def new(kind) do
    new(:global, kind, %{})
  end
  def new(kind, data) do
    new(:global, kind, data)
  end
  def new(stream, kind, data) when is_list(data) do
    %Event{stream: stream, kind: kind, data: Enum.into(data, %{})}
  end
  def new(stream, kind, data) do
    %Event{stream: stream, kind: kind, data: data}
  end
end
