defmodule Herald.Pipeline do
  @moduledoc """
  Pipeline is where messages are processed.

  All message processing is started by function `run/2`. 

  When `run/2` receives a message, it runs the following steps:
  * **pre_processing** - Will convert the message to a struct, using 
  the schema defined in route for the given queue;

  * **processor_caler** - Will call the `processor` defined in router for
  the given queue.
  """

  use GenServer

  require Logger

  alias Herald.Errors.MissingRouter

  defstruct [
    :schema,
    :message,
    :perform,
    :processor,

    result: :uncalled,
  ]

  @typedoc """
  Indicates to upper layers what must do doing with message.

  Possible values:
  * `:ack` - When the message is sucessfully processed;
  * `:delete` - When message must be deleted from broker
  after a processing error;
  * `:requeue` - When message must be reprocessed in
  future after a processing error.
  """
  @type to_perform :: 
    :ack |
    :delete |
    :requeue 

  @type t :: %__MODULE__{
    schema:    atom(),
    message:   map(),
    result:    any(),
    processor: fun(),
    perform:   to_perform(),
  }

  @doc false
  def start_link(_),
    do: GenServer.start_link(__MODULE__, nil)

  @doc false
  def init(_), do: {:ok, nil}

  @doc "call the function run/2"
  def handle_call({:run, queue, message}, _from, state),
    do: {:reply, run(queue, message), state}

  @doc """
  Process a given message.

  Receive the following arguments:
  * `queue` - The queue where message was received from;
  * `message` - The received message in a raw 
  state (i.e. the String as received from broker)

  This function must be called by plugins integrating
  Herald with Brokers.

  *Warning:* When you call this function without
  [configure a router](Herald.Router.html) for you
  application, it will raises the exception
  `Herald.Errors.MissingRouter`
  """
  @spec run(String.t(), String.t()) :: :ok | {:error, atom()}
  def run(queue, message) do
    Application.get_env(:herald, :router)
    |> case do
      router when is_nil(router) ->
        raise MissingRouter, message: """
        Router not found.

        You need set a router for your application, as bellow:

          config :herald,
            router: MyApp.Router

        See document bellow for more details:
        - https://hexdocs.pm/herald/Herald.Router.html
        """

      router ->
        message
        |> pre_processor(queue, router)
        |> processor_caller()
    end
  end

  defp pre_processor(message, queue, router) do
    case router.get_queue_route(queue) do
      {:ok, {schema, processor}} ->
        %__MODULE__{}
        |> Map.put(:schema, schema)
        |> Map.put(:processor, processor)
        |> Map.put(:message, schema.from_string(queue, message))

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp processor_caller(%{message: {:error, _reason}} = pipeline),
    do: Map.put(pipeline, :perform, :requeue)
  defp processor_caller(%{message: message, processor: processor} = pipeline) do
    case processor.(message) do
      {:ok, _} = result ->
        pipeline
        |> Map.put(:perform, :ack)
        |> Map.put(:result, result)

      {:error, :delete, _} = result ->
        pipeline
        |> Map.put(:result, result)
        |> Map.put(:perform, :delete)

      {:error, _} = result ->
        pipeline
        |> Map.put(:result, result)
        |> Map.put(:perform, :requeue)
    end
  end
end
