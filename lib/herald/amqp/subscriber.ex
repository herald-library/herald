defmodule Herald.AMQP.Subscriber do
  require Logger

  use AMQP
  use GenServer

  alias Herald.Message.Processing

  alias Herald.AMQP.Connection, as: ConnManager

  @doc false
  def init({queue, {schema, processor}} = _config) do
    ConnManager.request_channel(queue)

    {:ok, %{
      queue: queue,
      schema: schema,
      processor: processor
    }}
  end

  @doc false
  def start_link({queue, _} = args) do
    GenServer.start_link(__MODULE__, args, [
      name: String.to_atom(queue)
    ])
  end

  @doc false
  def handle_cast({:channel_created, channel}, state) do
    bind_to_queue(channel, state)

    {:noreply, Map.put(state, :channel, channel)}
  end

  @doc false
  def handle_info({:basic_consume_ok, %{consumer_tag: tag}}, state) do
    Logger.info("Consuming of tag #{tag} started")

    {:noreply, state}
  end

  @doc false
  def handle_info({:basic_deliver, payload, meta}, %{queue: queue, channel: channel} = state) do
    Logger.debug("Received a message in queue #{queue}")

    Processing.perform(:amqp, payload, state, meta)

    {:noreply, state}
  end

  defp bind_to_queue(channel, %{queue: queue, schema: schema, processor: processor}) do
    setup_queue(channel, queue)

    case Basic.consume(channel, queue) do
      {:ok, tag} ->
        Logger.info("Consume for #{queue} requested with tag #{tag}")

        :ok

      {:error, reason} ->
        raise "Error #{reason} consuming queue #{queue}"
    end
  end

  defp setup_queue(channel, queue) do
    Queue.declare(channel, queue, durable: true)
    Exchange.declare(channel, "#{queue}:exchange")
    Queue.bind(channel, queue, "#{queue}:exchange")
  end
end