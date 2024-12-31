defmodule LightningCSS.Paths do
  @moduledoc """
  This module groups utilities to read the paths from the application environment.
  """

  @doc """
  Returns the path to the executable.

  The executable may not be available if it was not yet installed.
  """
  def bin do
    target = LightningCSS.Architectures.target()
    name = "lightning_css-#{target}"

    Application.get_env(:lightning_css, :path) ||
      if Code.ensure_loaded?(Mix.Project) do
        Path.join(Path.dirname(Mix.Project.build_path()), name)
      else
        Path.expand("_build/#{name}")
      end
  end

  def cacertfile do
    Application.get_env(:lightning_css, :cacerts_path) || CAStore.file_path()
  end
end
