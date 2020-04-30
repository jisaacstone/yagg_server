# copied from the example here
# https://github.com/elixir-lang/gen_stage/blob/master/examples/gen_event.exs
defmodule YaggServer.EventManager do
  use GenStage

  def start_link(_) do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def sync_notify(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:notify, event}, timeout)
  end 

  ## Callbacks

  def init(:ok) do
    IO.inspect('EM started')
    {:producer, {:queue.new, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_call({:notify, event}, from, {queue, demand}) do
    IO.inspect(['Call Recieved', event, from, queue, demand])
    dispatch_events(:queue.in({from, event}, queue), demand, [])
  end

  def handle_demand(incoming_demand, {queue, demand}) do
    IO.inspect(['Demand Recieved', incoming_demand, queue, demand])
    dispatch_events(queue, incoming_demand + demand, [])
  end

  defp dispatch_events(queue, demand, events) do
    IO.inspect(['dispatch', queue, demand, events])
    with d when d > 0 <- demand,
         {{:value, {from, event}}, queue} <- :queue.out(queue) do
      GenStage.reply(from, :ok)
      dispatch_events(queue, demand - 1, [event | events])
    else
      _ -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end
