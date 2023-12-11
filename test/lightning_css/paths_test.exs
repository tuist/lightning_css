defmodule LightningCSS.PathsTest do
  use ExUnit.Case

  test "bin returns a valid path" do
    # Given
    got = LightningCSS.Paths.bin()

    # Then
    assert got != ""
  end
end
