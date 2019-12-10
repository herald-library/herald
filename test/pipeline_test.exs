defmodule Herald.PipelineTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureIO

  setup do
    [queue: "queue"]
  end

  setup %{queue: queue} do
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
end