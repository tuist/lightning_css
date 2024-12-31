defmodule LightningCSS do
  @moduledoc "README.md" |> File.read!() |> String.split("<!-- MDOC !-->") |> Enum.fetch!(1)

  use Application

  require Logger

  def start(_, _) do
    if !LightningCSS.Versions.configured() do
      Logger.warning("""
      lightning_css version is not configured. Please set it in your config files:

          config :lightning_css, :version, "#{LightningCSS.Versions.latest()}"
      """)
    end

    configured_version = LightningCSS.Versions.to_use()

    case LightningCSS.Versions.bin() do
      {:ok, ^configured_version} ->
        :ok

      {:ok, version} ->
        Logger.warning("""
        Outdated lightning_css version. Expected #{configured_version}, got #{version}. \
        Please run `mix lightning_css.install` or update the version in your config files.\
        """)

      :error ->
        :ok
    end

    Supervisor.start_link([], strategy: :one_for_one, name: __MODULE__.Supervisor)
  end

  @doc """
  Runs the given command with `args`.

  The given args will be appended to the configured args.
  The task output will be streamed directly to stdio. It
  returns the status of the underlying call.
  """
  @spec run(atom(), list(), Keyword.t()) :: :ok | {:error, {:exited, integer()}}
  def run(profile, extra_args, opts) when is_atom(profile) and is_list(extra_args) do
    watch = Keyword.get(opts, :watch, false)

    id =
      ([profile] ++ extra_args ++ [watch]) |> Enum.map_join("_", &to_string/1) |> String.to_atom()

    ref =
      __MODULE__.Supervisor
      |> Supervisor.start_child(
        Supervisor.child_spec(
          {LightningCSS.Runner,
           %{
             profile: profile,
             extra_args: extra_args,
             watch: watch
           }},
          id: id,
          restart: :transient
        )
      )
      |> case do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end
      |> Process.monitor()

    receive do
      {:DOWN, ^ref, _, _, {:error_and_no_watch, code}} ->
        {:error, {:exited, code}}

      _ ->
        :ok
    end
  end

  @doc """
  Installs, if not available, and then runs `lightning_css`.

  Returns the same as `run/2`.
  """
  @spec install_and_run(atom(), list(), Keyword.t()) :: integer()
  def install_and_run(profile, args, opts \\ []) do
    File.exists?(LightningCSS.Paths.bin()) || start_unique_install_worker()

    run(profile, args, opts)
  end

  defp start_unique_install_worker do
    ref =
      __MODULE__.Supervisor
      |> Supervisor.start_child(
        Supervisor.child_spec({Task, &LightningCSS.Installer.install/0},
          restart: :transient,
          id: __MODULE__.Installer
        )
      )
      |> case do
        {:ok, pid} -> pid
        {:error, {:already_started, pid}} -> pid
      end
      |> Process.monitor()

    receive do
      {:DOWN, ^ref, _, _, _} -> :ok
    end
  end
end
