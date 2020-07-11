defprotocol Herald.Adapters.Queue do
  @moduledoc """
  The `Herald.Adapters.Queue` protocol is responsible for handling
  queues from Message Broker and provide an interface to comunicate with
  Message Broker's queue.
  """

  @doc """
  Subscribe to Message Broker queue 
  """
  @spec subscribe(queue :: binary()) :: {:ok, list(map())} | {:error, term()}
  def subscribe(queue)

  @doc """
  Unsubscribe to Message Broker queue 
  """
  @spec unsubscribe(queue :: binary()) :: :ok | {:error, term()}
  def unsubscribe(queue)

  @doc """
  Acknowledge message from Message Broker queue 
  """
  @spec ack(message :: Herald.Message.t()) :: :ok | {:error, term()}
  def ack(message)
end
