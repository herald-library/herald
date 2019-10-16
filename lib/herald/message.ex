defmodule Herald.Message do
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
end