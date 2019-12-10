defmodule Herald.MessageTest do
  use ExUnit.Case, async: true

  test "should create schema" do
    assert Herald.TestMessage.schema() == %{
      age:  :integer,
      id:   :string,
      name: :string
    }
  end

  describe "from_string" do
    setup do
      [json: """
        {
          "id": "#{UUID.uuid4()}",
          "age": #{Enum.random(10..85)},
          "name": "#{Faker.Name.name()}",
          "extra": #{Enum.random(10..99)}
        }
      """]
    end

    setup %{json: json} do
      [decoded: Jason.decode!(json)]
    end
  
    test "should decode and assign payload", %{json: json, decoded: decoded} do
      message = Herald.TestMessage.from_string("queue", json)

      Enum.each(message.payload, fn {key, value} ->
        key = Atom.to_string(key)

        assert Map.get(decoded, key) == value
      end)
    end

    test "shouldn't add not declared fields in payload", %{json: json} do
      message = Herald.TestMessage.from_string("queue", json)

      assert not Enum.member?(message.payload, :extra)
      assert Map.keys(message.payload) == [:age, :id, :name]
    end
  end

  describe "new" do
    test "shoud validate required data" do
      message = Herald.TestMessage.new("queue", %{})

      assert %Herald.TestMessage{
        valid?: false,
        errors: [age: {"can't be blank", [validation: :required]}]
      } = message
    end

    test "should validate data types" do
      message = Herald.TestMessage.new("queue", %{
        age: "teen years",
        name: "123456"
      })

      assert %Herald.TestMessage{
        valid?: false,
        payload: %{
          name: "123456"
        },
        errors: [
          age: {"is invalid", [
            type: :integer,
            validation: :cast
          ]}
        ]
      } = message
    end

    test "shouldn't keep id nil" do
      message = Herald.TestMessage.new("queue", %{})

      assert %{id: id} = message
      assert not is_nil(id)
    end

    test "should set id" do
      id = UUID.uuid4()

      assert %{id: ^id} = Herald.TestMessage.new("queue", %{}, [
        id: id
      ])
    end
  end
end
