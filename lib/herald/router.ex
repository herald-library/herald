defmodule Herald.Router do
  @moduledoc """
  Provides the routes DSL.

  Routes is a way trought Herald know:

  * Which Message Schema uses to encode a
  message before send it;

  * Which function must be used to process
  a message when receives

  An router must be implemented as a module of your
  application, as bellow:

  ```elixir
  defmodule MyApp.Router do
    use Herald.Router
  
    route "my_queue1",
      schema: MyApp.Message1,
      processor: &MyApp.Message1.my_processor/1

    route "my_queue2",
      schema: MyApp.Message2,
      processor: &MyApp.Message2.my_processor/1
  end
  ```

  Each application using Herald must have only one
  router.
  
  You need to inform Herald where is your Router
  using application configurations, as bellow:

  ```elixir
  config :herald,
    router: MyApp.Router
  ```

  For more details, see `route/2`
  """

  alias Herald.Errors.InvalidRoute
  alias Herald.Errors.InvalidRouteProcessor

  defmacro __using__(_opts) do
    quote do
      @routes %{}

      @before_compile Herald.Router

      import Herald.Router
    end
  end

  @doc """
  Defines a `config` for a given `queue`.

  ### Config fields

  * `schema` - Represents a `struct` using
  `Herald.Message` which will be used to 
  represent any message received in `queue`;

  * `processor` - Represents a function
  which will process messages received in
  `queue`.

  For more details, see the [module doc](#content).
  """
  defmacro route(queue, _config = [schema: schema, processor: processor]) do
    quote do
      queue     = unquote(queue)
      schema    = unquote(schema)
      processor = unquote(processor)

      if not is_function(processor) do
        raise InvalidRouteProcessor,
          message: "Invalid processor! Processor must be a function"
      end

      @routes Map.put(@routes, queue, {schema,processor})
    end
  end
  defmacro route(queue, _config = [schema: schema]) do
    quote do
      queue     = unquote(queue)
      schema    = unquote(schema)
      processor = :empty

      @routes Map.put(@routes, queue, {schema,processor})
    end
  end
  defmacro route(_, _) do
    raise InvalidRoute, message: """
      Invalid route!

      A correct route must includes a queue name and
      schema to represent it, as bellow:

        route "queue",
          schema: MyApp.MessageSchema

      Additionally, it can includes a processor function,
      to indicates processor of messages received in that
      queue:

        route "queue",
          schema: MyApp.MessageSchema,
          processor: &MyApp.MessageSchema.func/1
    """
  end

  defmacro __before_compile__(_env) do
    quote do
      def routes(), do: @routes

      def get_queue_route(queue) do
        case Map.get(@routes, queue) do
          nil ->
            {:error, :queue_with_no_routes}

          route ->
            {:ok, route}
        end
      end
    end
  end
end