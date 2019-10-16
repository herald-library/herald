defmodule HeraldTest do
  use ExUnit.Case
  doctest Herald

  test "greets the world" do
    assert Herald.hello() == :world
  end
end
