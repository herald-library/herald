defmodule Herald.AMQP.Subscriber do
  use AMQP
  use GenServer

  require Logger

  def init({queue, {schema, processor}} = args) do
    {:ok, conn} = Connection.open(host: "broker") # TODO: GET FROM CONFIG
    {:ok, chan} = Channel.open(conn)
    {:ok, _}    = Queue.declare(chan, queue, durable: true)

    {:ok, _consumer_tag} = Basic.consume(chan, queue)

    {:ok, %{
      queue: queue,
      channel: chan,
      schema: schema,
      processor: processor
    }}
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, [])
  end

  # Confirmation sent by the broker after registering this process as a consumer
  def handle_info({:basic_consume_ok, _meta}, state) do
    {:noreply, state}
  end

  # Sent by the broker when the consumer is unexpectedly cancelled (such as after a queue deletion)
  def handle_info({:basic_cancel, _meta}, state) do
    {:stop, :normal, state}
  end

  # Confirmation sent by the broker to the consumer process after a Basic.cancel
  def handle_info({:basic_cancel_ok, _meta}, state) do
    {:noreply, state}
  end

  def handle_info(
    {:basic_deliver, payload, meta = %{delivery_tag: tag, message_id: message_id}},
    %{queue: queue, schema: schema} = state
  ) do
    call_args = 
      case message_id do
        :undefined -> [queue, payload]
        message_id -> [queue, payload, [id: message_id]]
      end

    schema
    |> apply(:from_string, call_args)
    |> case do
      %{id: message_id, valid?: true} = message ->
        Logger.debug("Parsed message #{inspect(message)}")
        Logger.info("Sending #{message_id} for processing")

        process_message(message, tag, state)

        {:noreply, state}

      %{valid?: false} = message ->
        Logger.debug("Parsed message #{inspect(message)}")
        Logger.error("Received a invalid message #{inspect(message)}")

        {:noreply, state}

      {:error, reason} ->
        Logger.error("Error #{inspect(reason)} when parse message #{inspect(payload)}")

        {:noreply, state}
    end
  end

  defp process_message(%{id: message_id} = message, tag, %{channel: chan, processor: function}) do
    Logger.info("Calling #{inspect(function)} for message #{message_id}")

    case function.(message) do
      {:ok, _} ->
        Logger.info("Processor for #{message_id} returns ok. Acknowledging")
        
        case Basic.ack(chan, tag) do
          :ok -> 
            Logger.info("Message #{message_id} acknowled")

          {:error, reason} ->
            Logger.error("Error #{inspect(reason)} when ack message #{message_id}")
        end

      {:error, reason} ->
        Logger.info("Processor for #{message_id} returns error #{reason}")

        case Basic.reject(chan, tag) do
          :ok -> 
            Logger.info("Message #{message_id} rejected")

          {:error, reason} ->
            Logger.error("Error #{inspect(reason)} when reject message #{message_id}")
        end

      {:error, :do_not_requeue, reason} ->
        Logger.warn("Processor for #{message_id} returns error #{reason}")
        Logger.warn("Dont requeue message #{message_id}")

        case Basic.reject(chan, tag, requeue: false) do
          :ok -> 
            Logger.info("Message #{message_id} rejected and not requeue")

          {:error, reason} ->
            Logger.error("Error #{inspect(reason)} when reject message #{message_id}")
        end

      another ->
        raise """
        Receiving invalid result #{inspect(another)} from processor #{inspect(function)}

        Processors return must match with {:ok, _}, {:error, _} or {:error, :discart, _}
        """
    end
  end
end