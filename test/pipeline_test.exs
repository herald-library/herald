defmodule Herald.PipelineTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  setup do
    [queue: "queue"]
  end

  setup %{queue: _queue} do
    [
      message: ~s({
        "id": "#{UUID.uuid4()}",
        "age": #{Enum.random(10..85)},
        "name": "#{Faker.Name.name()}",
        "extra": #{Enum.random(10..99)}
      })
    ]
  end

  describe "function run" do
    test "should raise error when router is not present", %{queue: queue, message: message} do
      assert_raise Herald.Errors.MissingRouter, fn ->
        Application.delete_env(:herald, :router)

        Herald.Pipeline.run(queue, message)
      end
    end

    test "should call processor function when all is ok", %{queue: queue, message: message} do
      Code.eval_quoted(quote do
        defmodule MyTestedRouter do
          use Herald.Router     

          def processor(message) do
            IO.puts("I'm called")

            {:ok, message}
          end

          route "queue",
            schema: Herald.TestMessage,
            processor: &__MODULE__.processor/1
        end
      end)

      Application.put_env(
        :herald,
        :router,
        MyTestedRouter
      )

      assert capture_io(fn ->
        Herald.Pipeline.run(queue, message) == true
      end) == "I'm called\n"
    end
  end

  describe "when processor returns {:ok, _} function run" do
    setup do
      Code.eval_quoted(quote do
        defmodule MyOkRouter do
          use Herald.Router     

          def processor(message) do
            {:ok, message}
          end

          route "queue",
            schema: Herald.TestMessage,
            processor: &__MODULE__.processor/1
        end
      end)

      Application.put_env(
        :herald,
        :router,
        MyOkRouter
      )
    end

    test "should set perform to :ack", %{queue: queue, message: message} do
      assert %Herald.Pipeline{perform: :ack} = Herald.Pipeline.run(queue, message)
    end
  end

  describe "when processor returns {:error, _} function run" do
    setup do
      Code.eval_quoted(quote do
        defmodule MyErrorRouter do
          use Herald.Router     

          def processor(message) do
            {:error, message}
          end

          route "queue",
            schema: Herald.TestMessage,
            processor: &__MODULE__.processor/1
        end
      end)

      Application.put_env(
        :herald,
        :router,
        MyErrorRouter
      )
    end

    test "should set perform to :requeue", %{queue: queue, message: message} do
      assert %Herald.Pipeline{perform: :requeue} = Herald.Pipeline.run(queue, message)
    end
  end

  describe "when processor returns {:error, :delete, _} function run" do
    setup do
      Code.eval_quoted(quote do
        defmodule MyErrorAndDeleRouter do
          use Herald.Router     

          def processor(message) do
            {:error, :delete, message}
          end

          route "queue",
            schema: Herald.TestMessage,
            processor: &__MODULE__.processor/1
        end
      end)

      Application.put_env(
        :herald,
        :router,
        MyErrorAndDeleRouter
      )
    end

    test "should set perform to :delete", %{queue: queue, message: message} do
      assert %Herald.Pipeline{perform: :delete} = Herald.Pipeline.run(queue, message)
    end
  end
end