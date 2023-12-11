defmodule LightningCSS.Versions do
  @moduledoc """
  This module groups functions to read default and remote versions of Lightning CSS.
  """

  # Package: https://registry.npmjs.org/lightningcss-cli/latest
  # Website: https://www.npmjs.com/package/lightningcss-cli
  @latest_version "1.22.0"

  @doc """
  Returns the version of the lightning_css executable.

  Returns `{:ok, version_string}` on success or `:error` when the executable
  is not available.
  """
  def bin do
    path = LightningCSS.Paths.bin()
    version_path = Path.dirname(path) |> Path.join("version")

    with true <- File.exists?(version_path),
         {:ok, result} <- File.read(version_path) do
      {:ok, String.trim(result)}
    else
      _ -> :error
    end
  end

  @doc """
  Returns the version of Lightning CSS that this package should use.
  """
  @spec configured() :: String.t() | nil
  def configured do
    Application.get_env(:lightning_css, :version)
  end

  @doc """
  Returns the configured version falling back to the latest if there's no version configured.
  """
  @spec to_use() :: String.t()
  def to_use do
    configured() || latest()
  end

  @doc """
  Returns the most recent Lightning CSS version known by this package.
  """
  @spec latest() :: String.t()
  def latest() do
    @latest_version
  end
end
