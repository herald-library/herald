defmodule Herald.Message do
  @moduledoc """
  Defines a Message.

  Message is a struct which represents data
  exchanged using a Broker queue.

  Any message which you expect receive or send
  in your application must be represented by a module,
  and this module must `use/2` `Herald.Message`
  and defines a `payload/1` for the represented
  message, as bellow:

  ```
  defmodule MyApp.UserRegistered do
    use Herald.Message

    payload do
      field :age,  :integer
      field :name, :string, required: true
    end
  end
  ```

  Any received Message is converted in a struct
  with the following fields:

    * `id` - A unique UUID for message. Can
    be used to filter duplicated messages;

    * `queue` - The queue where this message
    is received of will be sent;

    * `payload` - Content of message. Should be
    equals the payload defined by `payload/3`;

    * `valid?` - Indicates if message is valid,
    eg, with all fields have correct type, and
    if required fields are present.

  For understand how Herald defines which Message
  uses to represents a received message,
  see `Herald.Router`.
  """

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

  @doc """
  Defines the valid payload for a
  message, i.e. wrap all `field/3` calls
  """
  defmacro payload(do: block) do
    block
  end

  @doc """
  Defines a field of payload.

  Fields receives a `name`, `type`, and
  can have aditional options.

  ### Options

  * `required` - A `boolean` indicating
  if field is required to be present or
  not.
  """
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
      def new(queue, payload, opts \\ [])
      when is_binary(queue) and is_map(payload) do
        %__MODULE__{}
        |> set_message_id(opts)
        |> Map.put(:queue, queue)
        |> Map.put(:payload, payload)
        |> validate_payload()
      end

      @doc """
      Create new message from a JSON string

      Basicaly, its decode the JSON and forward it to `new/3`
      """
      @spec from_string(binary(), map(), any()) :: t()
      def from_string(queue, payload, opts \\ []) do
        case Jason.decode(payload) do
          {:ok, decoded} ->
            new(queue, decoded, opts)

          another ->
            another
        end
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

      if Mix.env() == :test do
        def schema(), do: @schema
      end
    end
  end
end