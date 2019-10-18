defmodule Herald.Router do
  defmacro __using__(_opts) do
    quote do
      @routes %{}

      @before_compile Herald.Router

      import Herald.Router
    end
  end

  defmacro route(queue, [schema: schema, processor: processor]) do
    quote do
      queue     = unquote(queue)
      schema    = unquote(schema)
      processor = unquote(processor)

      @routes Map.put(@routes, queue, {schema,processor})
    end
  end
  defmacro route(_, _) do
    raise """
      Invalid route! A example of correct route as bellow:

      route "queue",
        schema: MyApp.MessageSchema,
        processor: &MyApp.MessageSchema.func/1
    """
  end

  defmacro __before_compile__(_env) do
    quote do
      def routes(), do: @routes
    end
  end
end