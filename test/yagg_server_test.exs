defmodule YaggServerTest do
  use ExUnit.Case
  doctest YaggServer

  test "greets the world" do
    assert YaggServer.hello() == :world
  end
end
