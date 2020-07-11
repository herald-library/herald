defmodule Herald.TestBroker do  
end

defimpl Herald.Adapters.Connection, for: Herald.TestBroker do
  def connect(options) do
    if options[:error] do
      {:error, "An error example"}
    else
      :ok
    end
  end

  def disconnect(options) do
    if options[:error] do
      {:error, "An error example"}
    else
      :ok
    end
  end

  def is_connected?(options),
    do: options[:connected]
end

defmodule Herald.TestQueue do
  def generate_messages() do
    [
      %{
        "id" => Ecto.UUID.generate(),
        "name" => Faker.Name.name(),
        "age" => Faker.random_between(18, 99)
      }
    ]
  end
end

defimpl Herald.Adapters.Queue, for: Herald.TestQueue do
  import Herald.TestQueue

  def subscribe("error"),
    do: {:error, "An error example"}

  def subscribe(_queue) do
    {:ok, generate_messages()}
  end

  def unsubscribe("error"),
    do: {:error, "An error example"}

  def unsubscribe(_queue),
    do: :ok 

  def ack(%{id: "error"}),
    do: {:error, "An error example"}

  def ack(_message),
    do: :ok
end
