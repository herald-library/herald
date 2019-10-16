defmodule Herald.Message do
  @derive Jason.Encoder
  defstruct [
    id:      nil,
    queue:   nil,
    errors:  [],
    payload: nil
  ]

  @type t :: %__MODULE__{
    id:      UUID.t(),
    queue:   binary(),
    payload: map()
  }

  @doc false
  defmacro __using__(_opts) do
    quote do
      @schema %{}
      @required []

      import Herald.Message
    end
  end

  defmacro payload(do: block) do
    block
  end

  defmacro field(name, type, opts \\ []) do
    quote do
      name = unquote(name)
      type = unquote(type)
      opts = unquote(opts)

      if Keyword.get(opts, :required, false) do
        @required [name | @required]
      end

      @schema Map.put(@schema, name, type)
    end
  end

  @doc """
  Create new message and validate their payload
  """
  @spec new(binary(), map(), any()) :: t()
  def new(queue, payload, opts \\ []) do
    %__MODULE__{}
    |> set_message_id(opts)
    |> Map.put(:queue, queue)
    |> Map.put(:payload, payload)
  end

  defp set_message_id(%__MODULE__{} = message, opts) do
    Keyword.get(opts, :id)
    |> is_nil()
    |> if do
      Map.put(message, :id, UUID.uuid4())
    else
      Map.put(message, :id, Keyword.get(opts, :id))
    end
  end
end