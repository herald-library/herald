defmodule Herald.Message.Processing do
  @moduledoc """
  Responsible for processing messages.
  """

  require Logger

  @type source :: :amqp

  @type config :: {
    queue :: String.t(), 
    schema :: atom(),
    processor :: fun()
  }

  @spec perform(source, String.t(), config(), map()) :: :ok | {:error, any()}
  def perform(:amqp, payload, {queue, schema, processor}, %{delivery_tag: tag, message_id: message_id}) do
    parse_payload(schema, queue, payload, message_id)
    |> call_processor(processor)
    #|> ack_message()
  end

  defp parse_payload(schema, queue, payload, :undefined),
    do: parse_payload(schema, queue, payload)
  defp parse_payload(schema, queue, payload, message_id) when is_binary(message_id),
    do: parse_payload(schema, queue, payload, [id: message_id])
  defp parse_payload(schema, queue, payload, opts \\ []),
    do: apply(schema, :from_string, [queue, payload, opts])

  defp call_processor({:error, reason}, _),
    do: {:error, reason}
  defp call_processor(%{valid?: false}, _),
    do: {:error, :invalid_message}
  defp call_processor(%{id: message_id, valid?: true} = message, processor) do
    Logger.info("Calling function #{processor} for #{message_id}")

    case processor.(message) do
      result = {:ok, _} ->
        Logger.info("Processor for #{message_id} returns ok")

        result

      result = {:error, reason} ->
        Logger.info("Processor for #{message_id} returns error #{reason}")

        result

      result = {:error, :do_not_requeue, reason} ->
        Logger.info("Processor for #{message_id} returns error #{reason} and requires do not requeue")

        result

      result ->
        Logger.error("Processor for #{message_id} results in a invalid return #{result}")

        {:error, :invalid_result, result}
    end
  end

  defp ack_message({:ok, _}) do
  end
  defp ack_message({:error, _}) do
  end
  defp ack_message({:error, :do_not_requeue, _}) do
  end
  defp ack_message({:error, :invalid_result, _}) do
  end
end