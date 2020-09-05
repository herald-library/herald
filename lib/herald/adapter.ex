defmodule Herald.Adapter do
  @moduledoc """
  The adapter base module
  """

  @adapter_protocol "#{__MODULE__}s"
  @connection_protocol "#{@adapter_protocol}.Connection"
  @queue_protocol "#{@adapter_protocol}.Queue"

  @doc """
  Get implementation module from adapter's module
  """
  @spec get_adapter(atom(), module()) :: {:ok, module()} | {:error, binary()}
  def get_adapter(type, adapter) do
    module = get_module(type, adapter)

    if Code.ensure_loaded?(module) do
      {:ok, module}
    else
      {:error, "Herald Adapter #{adapter} not found"}
    end
  end

  @doc """
  Get implementation module from adapter's module
  """
  def get_adapter!(type, adapter) do
    case get_adapter(type, adapter) do
      {:ok, module} -> module
      {:error, reason} -> raise reason
    end
  end

  @spec get_module(atom(), module()) :: module()
  defp get_module(:connection, adapter),
    do: Module.concat(@connection_protocol, adapter)

  defp get_module(:queue, adapter),
    do: Module.concat(@queue_protocol, adapter)
end
