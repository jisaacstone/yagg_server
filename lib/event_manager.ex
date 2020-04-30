defmodule YaggServer.EventManager do
  use GenServer

  def start_link(options) do
    GenServer.start_link(__MODULE__, [], options)
  end

  def init(_) do
    {:ok, []}
  end

  def handle_call({:event, event}, _from, subscribers) do
    subs = Enum.filter(subscribers, &Process.alive?/1)
    Enum.map(subs, &Kernel.send(&1, {:event, event}))
    {:reply, :ok, subs}
  end

  def handle_call(:subscribe, {pid, _tag}, subscribers) do
    {:reply, :ok, [pid|subscribers]}
  end
end
