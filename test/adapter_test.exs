defmodule Herald.AdapterTest do
  use ExUnit.Case, async: true

  describe "With existent adapter so" do
    test "shoud return Connection adapter full module name" do
      adapter = Herald.Adapter.get_adapter(:connection, Herald.TestBroker)
      module = Herald.Adapters.Connection.Herald.TestBroker

      assert {:ok, module} == adapter
    end

    test "shoud return Queue adapter full module name" do
      adapter = Herald.Adapter.get_adapter(:queue, Herald.TestQueue)
      module = Herald.Adapters.Queue.Herald.TestQueue

      assert {:ok, module} == adapter
    end
  end

  describe "With inexistent adapter so" do
    test "shoudn't return Connection adapter and return an error" do
      adapter_name = Herald.TestBrokers
      adapter = Herald.Adapter.get_adapter(:connection, adapter_name)
      module = Elixir.Herald.TestBrokers

      assert {:error, "Herald Adapter #{module} not found"} == adapter
    end

    test "shoudn't return Queue adapter and return an error" do
      adapter_name = Herald.TestQueuee
      adapter = Herald.Adapter.get_adapter(:queue, adapter_name)
      module = Elixir.Herald.TestQueuee

      assert {:error, "Herald Adapter #{module} not found"} == adapter
    end
  end
end
