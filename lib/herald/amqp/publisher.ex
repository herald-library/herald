defmodule Herald.AMQP.Publisher do
  use AMQP

  def perform(%{valid?: true, queue: queue, id: message_id, payload: payload}) do
    {:ok, conn} = Connection.open(host: "broker") # TODO: GET FROM CONFIG
    {:ok, chan} = Channel.open(conn)
    {:ok, _}    = Queue.declare(chan, queue, durable: true)
    
    AMQP.Exchange.declare(chan, "#{queue}_exchange")
    AMQP.Queue.bind(chan, queue, "#{queue}_exchange")

    case Jason.encode(payload) do
      {:ok, encoded} ->
        Basic.publish(chan, "#{queue}_exchange", "", encoded, [
          persistent: true,
          message_id: message_id
        ])

      another -> another
    end
    
  end
  def perform(%{valid?: false}) do
    {:error, :invalid_message}
  end
end