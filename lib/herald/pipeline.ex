defmodule Herald.Pipeline do
  @moduledoc """
  Pipeline is where messages are processed.

  All message processing is started by function `run/3`. 

  When `run/3` receives a message, it runs the following steps:
  * *pre_processing* - Will convert the message to a struct, using 
  the schema defined in route for the given queue;
  * *processor_caler* - Will call the `processor` defined in router for
  the given queue.
  """

  alias Herald.Errors.MissingRouter

  defstruct [
    :schema,
    :processor,
    :message,
    :caller_result
  ]

  @doc """
  Process a given message.

  Receive the following arguments:
  * `queue` - The queue where message was received from;
  * `message` - The received message in a raw 
  state (i.e. the String as received from broker)

  *Warning:* When you call this function without
  [configure a router](Herald.Router.html) for you
  application, it will raises the exception
  `Herald.Errors.MissingRouter`
  """
  @spec run(String.t(), String.t(), String.t()) :: :ok | {:error, atom()}
  def run(queue, message, opts \\ []) do
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

  defp processor_caller(%{message: message, processor: processor} = pipeline) do
    result = 
      message
      |> processor.()

    Map.put(pipeline, :caller_result, result)
  end
end
