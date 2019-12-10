defmodule Herald.Pipeline do
  @moduledoc """
  Pipeline is where messages are processed.
  """

  alias Herald.Errors.MissingRouter

  defstruct [
    :schema,
    :processor,
    :message,
    :caller_result
  ]

  @doc "Runs the pipeline for a message"
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
        |> post_processor()
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

    pipeline
    |> Map.put(:caller_result, result)
  end

  defp post_processor(%{caller_result: result} = pipeline) do
    case result do
      {:ok, _} -> :ok
      {:error, reason} -> :error
    end
  end
end
