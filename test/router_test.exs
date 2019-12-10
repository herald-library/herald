defmodule Herald.RouterTest do
  use ExUnit.Case, async: true

  setup do
    [router: Herald.TestRouter]
  end

  setup %{router: router} do
    [routes: router.routes()]
  end

  setup %{routes: routes} do
    [route_keys: Map.keys(routes)]
  end

  setup %{routes: routes} do
    [route_values: Map.values(routes)]
  end

  test "should store routes into a Map", %{routes: routes} do
    assert is_map(routes)
  end

  describe "route keys" do
    test "should represent queue names", %{route_keys: route_keys} do
      assert route_keys == ~w(with_processor without_processor)
    end
  end

  describe "route values" do
    test "should be tuple with two size", %{route_values: route_values} do
      Enum.each(route_values, fn route_config ->
        assert is_tuple(route_config)
        assert tuple_size(route_config) == 2
      end)
    end

    test "should store message schema in the first position", %{route_values: route_values} do
      Enum.each(route_values, fn {message, _} ->
        assert message == Herald.TestMessage
      end)
    end

    test "should store processors in the second position", %{route_values: route_values} do
      Enum.each(route_values, fn {_, processor} ->
        assert is_function(processor) or processor == :empty
      end)
    end

    test "should set processor as :empty when it is not declared", %{routes: routes} do
      Enum.each(routes,
        fn
          {"with_processor", {_, processor}} ->
            assert is_function(processor)

          {"without_processor", {_, processor}} ->
            assert processor == :empty
        end)
    end
  end

  describe "when compile a module using this" do
    test "should raise error when :schema is not declared" do
      assert_raise Herald.Errors.InvalidRoute, fn ->
        Code.eval_quoted(quote do
          defmodule InvalidRouter do
            use Herald.Router

            route "queue",
              processor: fn _ -> :error end
          end
        end)
      end
    end

    test "should raise error when :processor is not a function" do
      assert_raise Herald.Errors.InvalidRouteProcessor, fn ->
        Code.eval_quoted(quote do
          defmodule InvalidRouter do
            use Herald.Router

            route "queue",
              schema: Herald.TestMessage,
              processor: Enum.random(["string", :atom, 1_000_000])
          end
        end)
      end
    end
  end

  describe "function get_queue_route" do
    test "should return {:ok, route} when route exists", %{router: router} do
      assert router.get_queue_route("with_processor")
      |> Kernel.==({:ok, {Herald.TestMessage, &Herald.TestMessage.processor/1}})
    end

    test "should return {:error, :queue_with_no_routes} when route does not exists", %{router: router} do
      assert router.get_queue_route("inexistent")
      |> Kernel.==({:error, :queue_with_no_routes})
    end
  end
end