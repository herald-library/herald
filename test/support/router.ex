defmodule Herald.TestRouter do
  use Herald.Router

  route "with_processor",
    schema: Herald.TestMessage,
    processor: &Herald.TestMessage.processor/1

  route "without_processor",
    schema: Herald.TestMessage
end