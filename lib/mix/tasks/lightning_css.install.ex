defmodule Mix.Tasks.LightningCss.Install do
  @moduledoc """
  Installs lightning_css under `_build`.

  ```bash
  $ mix lightning_css.install
  $ mix lightning_css.install --if-missing
  ```

  By default, it installs #{LightningCSS.latest_version()} but you
  can configure it in your config files, such as:

      config :lightning_css, :version, "#{LightningCSS.latest_version()}"

  ## Options

      * `--runtime-config` - load the runtime configuration
        before executing command

      * `--if-missing` - install only if the given version
        does not exist
  """

  @shortdoc "Installs lightning_css under _build"
  @compile {:no_warn_undefined, Mix}

  use Mix.Task

  @impl true
  def run(args) do
    valid_options = [runtime_config: :boolean, if_missing: :boolean]

    case OptionParser.parse_head!(args, strict: valid_options) do
      {opts, []} ->
        if opts[:runtime_config], do: Mix.Task.run("app.config")

        if opts[:if_missing] && latest_version?() do
          :ok
        else
          if function_exported?(Mix, :ensure_application!, 1) do
            Mix.ensure_application!(:inets)
            Mix.ensure_application!(:ssl)
          end

          LightningCSS.install()
        end

      {_, _} ->
        Mix.raise("""
        Invalid arguments to lightning_css.install, expected one of:

            mix lightning_css.install
            mix lightning_css.install --runtime-config
            mix lightning_css.install --if-missing
        """)
    end
  end

  defp latest_version?() do
    version = LightningCSS.configured_version()
    match?({:ok, ^version}, LightningCSS.bin_version())
  end
end
