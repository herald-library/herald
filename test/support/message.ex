defmodule Herald.TestMessage do
  use Herald.Message

  payload do
    field :id,   :string
    field :name, :string
    field :age,  :integer, required: true
  end
end