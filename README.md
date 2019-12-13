# Herald

![](https://github.com/radsquare/herald/workflows/Elixir%20CI/badge.svg)

Herald aims to be a tool which allow companies implement this pattern in a simple way, releasing the developers to think in business logic instead details about broker communication, message exchange, etc.

A complemente documentation can be found at [https://hexdocs.pm/herald](https://hexdocs.pm/herald).


## Installation

Add in your `mix.exs` and run `mix deps.get`:

```elixir
def deps do
  [
    {:herald, "~> 0.1.0"}
  ]
end
```

## Plugins

Herald support the following Message Brokers:

* [Herald AMQP](https://hexdocs.pm/herald_amqp).

The following plugins is in our ROADMAP:

* Herald SQS;
* GCP Cloud Pub/Sub;
* Apache Kafka.
