defmodule Herald.Message do
  @doc false
  defmacro __using__(_opts) do
    quote do
      @schema %{}
      @required []

      @before_compile Herald.Message

      @derive {Jason.Encoder, except: [:errors, :valid?]}
      defstruct [
        id:      nil,
        queue:   nil,
        errors:  [],
        payload: nil,
        valid?:  false
      ]

      @type t :: %__MODULE__{
        id:      UUID.t(),
        queue:   binary(),
        payload: map(),
        valid?:  boolean()
      }

      import Ecto.Changeset
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

  defmacro __before_compile__(_env) do
    quote do
      @doc """
      Create new message and validate their payload
      """
      @spec new(binary(), map(), any()) :: t()
      def new(queue, payload, opts \\ []) do
        %__MODULE__{}
        |> set_message_id(opts)
        |> Map.put(:queue, queue)
        |> Map.put(:payload, payload)
        |> validate_payload()
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

      defp validate_payload(%__MODULE__{payload: payload} = message) do
        %{valid?: valid, errors: errors, changes: changes} =
          {Map.new(), @schema}
          |> cast(payload, Map.keys(@schema))
          |> validate_required(@required)

        message
        |> Map.put(:valid?, valid)
        |> Map.put(:errors, errors)
        |> Map.put(:payload, changes)
      end
    end
  end
end