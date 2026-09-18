defmodule LightningCSS.ArchitecturesTest do
  use ExUnit.Case, async: true

  alias LightningCSS.Architectures

  describe "linux_target/2" do
    test "maps every 64-bit arch spelling Erlang reports onto a published package" do
      for {arch, expected} <- [
            {"amd64", "x64"},
            {"x86_64", "x64"},
            {"arm", "arm64"},
            {"arm64", "arm64"},
            {"aarch64", "arm64"}
          ],
          toolchain <- ~w[gnu musl] do
        assert Architectures.linux_target(arch, toolchain) ==
                 "linux-#{expected}-#{toolchain}"
      end
    end

    test "aarch64 resolves for both toolchains" do
      assert Architectures.linux_target("aarch64", "musl") == "linux-arm64-musl"
      assert Architectures.linux_target("aarch64", "gnu") == "linux-arm64-gnu"
    end

    test "raises on an unknown architecture" do
      assert_raise RuntimeError, ~r/not available for architecture/, fn ->
        Architectures.linux_target("riscv64", "gnu")
      end
    end

    test "raises on an unsupported toolchain" do
      assert_raise RuntimeError, ~r/not available for architecture/, fn ->
        Architectures.linux_target("aarch64", "uclibc")
      end
    end
  end
end
