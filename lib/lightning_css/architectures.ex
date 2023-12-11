defmodule LightningCSS.Architectures do
  @moduledoc """
  This module groups functions to read the architecture from the environment in which the code is running.
  """

  # Available targets: https://registry.npmjs.org/lightningcss-cli/latest
  # credo:disable-for-next-line
  def target do
    case :os.type() do
      # Assuming it's an x86 CPU
      {:win32, _} ->
        wordsize = :erlang.system_info(:wordsize)

        if wordsize == 8 do
          "win32-x64"
        else
          "win32-ia32"
        end

      {:unix, osname} ->
        arch_str = :erlang.system_info(:system_architecture)
        [arch | _] = arch_str |> List.to_string() |> String.split("-")

        case arch do
          "amd64" -> "#{osname}-x64"
          "x86_64" -> "#{osname}-x64"
          "i686" -> "#{osname}-ia32"
          "i386" -> "#{osname}-ia32"
          "aarch64" -> "#{osname}-arm64"
          "arm" when osname == :darwin -> "darwin-arm64"
          "arm" -> "#{osname}-arm"
          "armv7" <> _ -> "#{osname}-arm"
          _ -> raise "lightning_css is not available for architecture: #{arch_str}"
        end
    end
  end
end
