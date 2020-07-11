defprotocol Herald.Adapters.Connection do
  @moduledoc """
  The `Herald.Adapters.Connection` protocol is responsible for preparing and
  providing the connection with Message Broker.

  All `Herald.Adapters.Connection` functions are executed in the caller process which
  means it's safe to, for example, raise exceptions or do blocking calls as
  they won't affect the connection process.
  """

  @doc """
  Connect to Message Broker using connection 
  """
  @spec connect(conn_options :: keyword()) :: :ok | {:error, term()}
  def connect(conn_options)

  @doc """
  Disconnect from Message Broker 
  """
  @spec disconnect(conn_options :: keyword()) :: :ok | {:error, term()}
  def disconnect(conn_options)

  @doc """
  Check if there's any open connection with Message Broker 
  """
  @spec is_connected?(conn_options :: keyword()) :: boolean()
  def is_connected?(conn_options)
end
