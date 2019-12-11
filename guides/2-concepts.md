# Concepts

This section aims to introduce you the main concepts you need to know to understand Herald.

## Message Schema

Not rarely, with the growth or systems evolutions, problems comes too!

A lot of companies have a lot of problems with inconsistent messages between systems, mainly because the message payload was changed in some systems without necessarily having been updated in the other.

Herald prevent this introducing a concept of Message Schema, i.e., a strong payload definition for message, which will be used to validate and represent a message.

Bellow, you can see a example of Message Schema implementation:

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

Using `Herald.Message.field/3` you can define all fields which should be present in your message, as well your types. Case any field must be present, you must set option `required` as `true`, as shown above.

Note that you message have any field which was not declared in your payload, this field will be discarted.

*Note:* Internally, Message Schemas are validated using `Ecto`, allowing extensibility of these validations in the future.

See `Herald.Message` for more details.

## Message Routes

Routes let Herald to known what [Message Schema](#message-schema)] use to decode messages received in the given queue, and what is the function which must be called to process these message.

See the example bellow:

```elixir
defmodule MyApp.Router do
  use Herald.Router

  route "user:created",
    schema: MyApp.UserMessage,
    processor: &MyApp.func/1
end
```

This router tells the following to Herald:

* Always a message is received in the queue `user:created`, Herald must use the payload defined in module `MyApp.UserMessage` to validate and represent this message;

* After this message is parsed and converted into a struct of `MyApp.UserMessage`, the function `MyApp.func/1` will be called passing this struct for these function;

See `Herald.Router` for more details.

## Message Pipeline

The message pipeline is the central component of Herald, exposed by the function `Herald.Pipeline.run/3`, and called by [Herald AMQP](https://hexdocs.pm/herald_amqp) and [Herald SQS](https://hexdocs.pm/herald_sqs) to process messages.

Basically, this function will receive a raw message and the queue where it originated, and will:

* Get the [route](#message-routes) details for the given queue;
* Decode the message using [message schema](#message-schema);
* Once message is decoded, send it to their processor;
* Returns to the caller function

If you want to develop a plugin to integrate Herald with a message broker, the function `Herald.Pipeline.run/3` will be the point of integration of your plugin with Herald Core.

See `Herald.Pipeline` for more details.