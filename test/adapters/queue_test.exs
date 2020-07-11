defmodule Herald.Adapters.QueueTest do
  use ExUnit.Case, async: true
  doctest Herald.Adapters.Queue
  doctest Herald.Adapters.Queue.Herald.TestQueue

  alias Herald.Adapters.Queue.Herald.TestQueue

  describe "With successful queue" do
    setup do
      %{queue: "success"}
    end

    test "should subscribe to broker", %{queue: queue} do
      {:ok, messages} = TestQueue.subscribe queue 
      assert messages |> length() > 0
    end

    test "should unsubscribe from broker", %{queue: queue} do
      assert :ok == TestQueue.unsubscribe queue
    end

    test "should ack an message from broker", %{queue: queue} do
      assert TestQueue.ack %{id: queue}
    end
  end

  describe "With error queue" do
    setup do
      %{queue: "error"}
    end

    test "shouldn't subscribe to broker", %{queue: queue} do
      assert {:error, "An error example"} == TestQueue.subscribe queue
    end

    test "shouldn't unsubscribe from broker", %{queue: queue} do
      assert {:error, "An error example"} == TestQueue.unsubscribe queue
    end

    test "shouldn't ack an message from broker", %{queue: queue} do
      assert {:error, "An error example"} == TestQueue.ack %{id: queue}
    end
  end
end
