defmodule LightningCSSTest do
  use ExUnit.Case

  test "bin_path returns a valid path" do
    # Given
    got = LightningCSS.bin_path()

    # Then
    dbg(got)
    assert got != ""
  end
end
