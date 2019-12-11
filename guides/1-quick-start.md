# Quick start

Message exchange is a widely used pattern in technology world, mainly in microservices ecosystems.

Herald aims to be a tool which allow companies implement this pattern in a simple way, releasing the developers to think in business logic instead details about broker communication, message exchange, etc.

To getting started with Herald, execute the following steps:

## Install it

Add in your mix.exs and run `mix deps.get`:

```elixir
def deps do
  [
    {:herald, "~> 0.1.0"}
  ]
end
```

## Install broker plugin

Install one of the following libraries:

* [Herald AMQP](https://hexdocs.pm/herald_amqp)
* [Herald SQS](https://hexdocs.pm/herald_sqs)

## Create a Message Schema:

In Message Schema you'll defines what is the expected fields for some messages:

```elixir
defmodule MyApp.UserMessage do
  use Herald.Message

  payload do
    field :id,   :integer, required: true
    field :age,  :integer, required: true
    field :name, :string,  required: true
  end
end
```

## Create processor function

Processor function will work as a callback function when a message is received. In our case, we created the message in the same module of `MyApp.UserMessage`, but your can create where your business logic requires:

```elixir
defmodule MyApp.UserMessage do
  use Herald.Message

  payload do
    field :id,   :integer, required: true
    field :age,  :integer, required: true
    field :name, :string,  required: true
  end

  def my_processor(%MyApp.UserMessage{} = message) do
    if do_some_stuff_with(message) do
      {:ok, message}
    else
      {:error, :my_bad_error}
    end
  end
end
```

## Create Router

Router will tell for Herald what Message Schema and processor use for process each message received.

In example bellow, any message received in queue `user:created` will be validated by schema MyApp.UserMessage and processed by function `&MyApp.UserMessage.func/1`:

```elixir
defmodule MyApp.Router do
  use Herald.Router

  route "user:created",
    schema: MyApp.UserMessage,
    processor: &MyApp.UserMessage.func/1
end
```

## Configure app

Finaly, need inform Herald what is the module where Router is configured:

```elixir
config :herald,
  router: MyApp.Router
```