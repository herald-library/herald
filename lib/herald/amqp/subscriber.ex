defmodule Herald.AMQP.Subscriber do
  require Logger

  use GenServer

  alias Herald.AMQP.Connection, as: ConnManager

  @doc false
  def init({queue, {schema, processor}} = _config) do
    Logger.info("Starting children for queue `#{queue}`")

    ConnManager.request_channel(__MODULE__)

    {:ok, {queue, schema, processor}}
  end

  @doc false
  def start_link(args),
    do: GenServer.start_link(__MODULE__, args, [])

  @doc false
  def channel_created(channel),
    do: GenServer.cast(__MODULE__, {:channel_created, channel})

  @doc false
  def handle_call({:channel_created, channel}) do
    {:noreply, channel}
  end
end