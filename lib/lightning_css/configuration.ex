defmodule LightningCSS.Configuration do
  @moduledoc """
  This module groups functions to read the configuration from the application environment.
  """
  @doc """
  Returns the configuration for the given profile.

  Returns nil if the profile does not exist.
  """
  def config_for!(profile) when is_atom(profile) do
    Application.get_env(:lightning_css, profile) ||
      raise ArgumentError, """
      unknown lightning_css profile. Make sure the profile is defined in your config/config.exs file, such as:

          config :lightning_css,
            #{profile}: [
              args: ~w(css/app.css --bundle --targets='last 10 versions' --output-dir=../priv/static/assets),
              cd: Path.expand("../assets", __DIR__),
              env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
            ]
      """
  end
end
