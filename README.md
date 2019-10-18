# Herald

Herald is a library to exchange async messages between systems through a message broker.

These library support AMQP based message brokers

## Installation

Add in your `mix.exs` and run `mix deps.get`:

```elixir
def deps do
  [
    {:herald, "~> 0.1.0"}
  ]
end
```

# Getting start

## Subscriptions

1. Create you message schema:

```elixir
defmodule MyApp.Message do
  use Herald.Message

  payload do
    field :age,  :integer
    field :name, :string, required: true
  end
end
```

2. Create your processor function

Processor function will work as a callback function when a message is received.

```elixir
defmodule MyApp.Message do
  use Herald.Message

  payload do
    field :age,  :integer
    field :name, :string, required: true
  end

  def my_processor(%MyApp.Message{} = message) do
    if do_some_stuff_with(message) do
      {:ok, message}
    else
      {:error, :my_bad_error}
    end
  end
end
```

3. Create your Router

Router will say for library what `schema` and `processor` use for each queue.

In example bellow, any message received in queue `my_queue` will be validated by schema `MyApp.Message`, and processed by function `&MyApp.Message.my_processor/1`.

```elixir
defmodule MyApp.Router do
  use Herald.Router

  route "my_queue",
    schema: MyApp.Message,
    processor: &MyApp.Message.my_processor/1
end
```

4. Configure this

Finaly, need inform Herald what is the module where router is configured:

```elixir
config :herald,
  router: Develop.Router
```

## Publishing

Publications can be performed as bellow:

```elixir
alias Herald.AMQP.Publisher

MyApp.Message.new("queue", %{
  "age"  => 70,
  "name" => "Dennis Ritchie"
})
|> Publisher.perform()
```

# Documentation

Docs for this library can
be found at [https://hexdocs.pm/herald](https://hexdocs.pm/herald).

