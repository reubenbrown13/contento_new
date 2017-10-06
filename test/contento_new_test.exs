defmodule Contento.NewTest do
  use ExUnit.Case
  doctest Contento.New

  test "greets the world" do
    assert Contento.New.hello() == :world
  end
end
