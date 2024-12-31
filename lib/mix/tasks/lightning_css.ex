defmodule Mix.Tasks.LightningCss do
  @shortdoc "Invokes lightning_css with the profile and args"
  @moduledoc """
  Runs lightning_css with the given profile and args.

  ```bash
  $ mix lightning_css --runtime-config dev
  ```

  The task will install lightning_css if it hasn't been installed previously
  via the `mix lightning_css.install` task.

  ## Options

      * `--runtime-config` - load the runtime configuration
      before executing command
      * `--watch` - watches for file changes and re-runs Lightning CSS when any of the matched files changes.

  """

  use Mix.Task

  @compile {:no_warn_undefined, Mix}

  @impl true
  def run(args) do
    switches = [runtime_config: :boolean, watch: :boolean]
    {opts, remaining_args} = OptionParser.parse_head!(args, switches: switches)

    if function_exported?(Mix, :ensure_application!, 1) do
      Mix.ensure_application!(:inets)
      Mix.ensure_application!(:ssl)
    end

    if opts[:runtime_config] do
      # Loads and configures all registered apps.
      Mix.Task.run("app.config")
    else
      # Ensures that the application and their child application are started.
      Application.ensure_all_started(:lightning_css)
    end

    Mix.Task.reenable("lightning_css")
    install_and_run(remaining_args, watch: Keyword.get(opts, :watch, false))
  end

  defp install_and_run([profile | args] = all, opts) do
    case LightningCSS.install_and_run(String.to_atom(profile), args, opts) do
      :ok ->
        :ok

      {:error, {:exited, status}} ->
        Mix.raise(
          "`mix lightning_css #{Enum.join(all, " ")}` exited caused by lightningcss failing with status code #{status}"
        )
    end
  end

  defp install_and_run([], _opts) do
    Mix.raise("`mix lightning_css` expects the profile as argument")
  end
end
