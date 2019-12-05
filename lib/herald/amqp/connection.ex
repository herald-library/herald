defmodule Herald.AMQP.Connection do
  use AMQP
  use GenServer
  use Application

  require Logger

  @max_attemps 10

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, [
      name: __MODULE__
    ])
  end

  def init(:ok) do
    children = get_children()

    Supervisor.start_link(children, [
      strategy: :one_for_one,
      name: Herald.AMQP.Supervisor
    ])
    
    connect(@max_attemps)
  end

  defp get_children() do
    Application.get_env(:herald, :router)
    |> get_children!()
  end
  defp get_children!(nil) do
    raise """
    You application dont implement a Router.

    See Herald.Router documentation for more details.
    """
  end
  defp get_children!(router) do
    apply(router, :routes, [])
    |> Enum.map(fn {queue, _} = route_spec ->
      %{
        id: String.to_atom(queue),
        start: {
          Herald.AMQP.Subscriber,
          :start_link,
          [route_spec]
        }
      }
    end)
  end

  defp connect(attempt) do
    get_conn_opts()
    |> AMQP.Connection.open()
    |> case do
      {:ok, %{pid: pid} = conn} -> 
        Process.link(pid)

        {:ok, %{conn: conn, channel: nil}}

      {:error, _reason} ->
        if attempt > 0 do
          Process.sleep(300)

          attempt
          |> Kernel.-(1)
          |> connect()
        else
          raise "Error when connect with RabbitMQ"
        end
    end
  end

  defp get_conn_opts() do
    case Application.get_env(:herald, :amqp_url) do
      {:system, environment} ->
        System.get_env(environment) || "amqp://localhost"

      amqp_url ->
        amqp_url || "amqp://localhost"
    end
    |> URI.parse()
    |> get_conn_opts()
  end
  defp get_conn_opts(%URI{} = info) do
    Map.from_struct(info)
    |> Enum.reduce(Keyword.new(), fn {key, value}, acc ->
      put_conn_opts(acc, key, value)
    end)
  end
  
  defp put_conn_opts(info, _key, nil),
    do: info
  defp put_conn_opts(info, :userinfo, value) do
    case String.split(value, ":") do
      [user, ""] ->
        Keyword.put(info, :username, user)

      ["", password] ->
        Keyword.put(info, :password, password)

      [user, password] ->
        info
        |> Keyword.put(:username, user)
        |> Keyword.put(:password, password)
    end
  end
  defp put_conn_opts(info, key, value) do
    Keyword.put(info, key, value)
  end

  def request_channel(queue) do
    GenServer.cast(__MODULE__, {:get_channel, queue})
  end

  def handle_cast({:get_channel, queue}, %{conn: conn, channel: nil}) do
    case Channel.open(conn) do
      {:ok, channel} ->
        GenServer.cast(String.to_atom(queue), {:channel_created, channel})

        {:noreply, %{conn: conn, channel: channel}}

      {:error, reason} ->
        {:error, reason}
    end
  end
  def handle_cast({:get_channel, queue}, %{conn: conn, channel: channel}) do
    GenServer.cast(String.to_atom(queue), {:channel_created, channel})

    {:noreply, %{conn: conn, channel: channel}}
  end
end