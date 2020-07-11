defmodule Herald.Adapters.ConnectionTest do
  use ExUnit.Case, async: true
  doctest Herald.Adapters.Connection
  doctest Herald.Adapters.Connection.Herald.TestBroker

  alias Herald.Adapters.Connection.Herald.TestBroker

  describe "With successful options" do
    setup do
      %{options: [error: false, connected: true]}
    end

    test "should connect to broker", %{options: options} do
      assert :ok == TestBroker.connect options
    end

    test "should disconnect from broker", %{options: options} do
      assert :ok == TestBroker.disconnect options
    end

    test "should return an active connection from broker", %{options: options} do
      assert TestBroker.is_connected? options
    end
  end

  describe "With error options" do
    setup do
      %{options: [error: true, connected: false]}
    end

    test "shouldn't connect to broker", %{options: options} do
      assert {:error, "An error example"} == TestBroker.connect options
    end

    test "shouldn't disconnect from broker", %{options: options} do
      assert {:error, "An error example"} == TestBroker.disconnect options
    end

    test "shouldn't return an active connection from broker", %{options: options} do
      assert not TestBroker.is_connected? options
    end
  end
end
