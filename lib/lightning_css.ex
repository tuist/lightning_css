defmodule LightningCSS do
  @moduledoc """
  Lightning CSS
  """

  # Package: https://registry.npmjs.org/lightningcss-cli/latest
  # Website: https://www.npmjs.com/package/lightningcss-cli
  @latest_version "1.22.0"

  use Application
  require Logger

  def start(_, _) do
    unless Application.get_env(:lightning_css, :version) do
      Logger.warning("""
      lightning_css version is not configured. Please set it in your config files:

          config :lightning_css, :version, "#{latest_version()}"
      """)
    end

    configured_version = configured_version()

    case bin_version() do
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
  Returns the version of Lightning CSS that this package should use.
  """
  @spec configured_version() :: String.t()
  def configured_version do
    Application.get_env(:lightning_css, :version, latest_version())
  end

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

  @doc """
  Returns the most recent Lightning CSS version known by this package.
  """
  @spec latest_version() :: String.t()
  def latest_version() do
    @latest_version
  end

  @doc """
  Returns the version of the lightning_css executable.

  Returns `{:ok, version_string}` on success or `:error` when the executable
  is not available.
  """
  def bin_version do
    path = bin_path()
    version_path = Path.dirname(path) |> Path.join("version")
    with true <- File.exists?(version_path),
         {:ok, result} <- File.read(version_path) do
      {:ok, String.trim(result)}
    else
      _ -> :error
    end
  end

  @doc """
  Returns the path to the executable.

  The executable may not be available if it was not yet installed.
  """
  def bin_path do
    name = "lightning_css-#{target()}"

    Application.get_env(:lightning_css, :path) ||
      if Code.ensure_loaded?(Mix.Project) do
        Path.join(Path.dirname(Mix.Project.build_path()), name)
      else
        Path.expand("_build/#{name}")
      end
  end

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

  @doc """
  Runs the given command with `args`.

  The given args will be appended to the configured args.
  The task output will be streamed directly to stdio. It
  returns the status of the underlying call.
  """
  def run(profile, extra_args) when is_atom(profile) and is_list(extra_args) do
    config = config_for!(profile)
    args = config[:args] || []

    if args == [] and extra_args == [] do
      raise "no arguments passed to lightning_css"
    end


    opts = [
      cd: config[:cd] || File.cwd!(),
      env: config[:env] || %{},
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    bin_path()
    |> System.cmd(args ++ extra_args, opts)
    |> elem(1)
  end


  @doc """
  Installs, if not available, and then runs `lightning_css`.

  Returns the same as `run/2`.
  """
  def install_and_run(profile, args) do
    File.exists?(bin_path()) || start_unique_install_worker()

    run(profile, args)
  end

  defp start_unique_install_worker() do
    ref =
      __MODULE__.Supervisor
      |> Supervisor.start_child(
        Supervisor.child_spec({Task, &install/0}, restart: :transient, id: __MODULE__.Installer)
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


  @doc """
  Installs lightning_css with `configured_version/0`.
  """
  def install do
    version = configured_version()
    tmp_opts = if System.get_env("MIX_XDG"), do: %{os: :linux}, else: %{}

    tmp_dir =
      freshdir_p(:filename.basedir(:user_cache, "lightning_css", tmp_opts)) ||
        freshdir_p(Path.join(System.tmp_dir!(), "lightning_css")) ||
        raise "could not install lightning_css. Set MIX_XGD=1 and then set XDG_CACHE_HOME to the path you want to use as cache"

    url = "https://registry.npmjs.org/lightningcss-cli-#{target()}/-/lightningcss-cli-#{target()}-#{version}.tgz"

    tar = fetch_body!(url)

    case :erl_tar.extract({:binary, tar}, [:compressed, cwd: to_charlist(tmp_dir)]) do
      :ok -> :ok
      other -> raise "couldn't unpack archive: #{inspect(other)}"
    end

    bin_path = bin_path()
    File.mkdir_p!(Path.dirname(bin_path))

    case :os.type() do
      {:win32, _} ->
        File.cp!(Path.join([tmp_dir, "package", "lightningcss.exe"]), bin_path)
        File.write!(Path.join(Path.dirname(bin_path), "version"), version)
      _ ->
        File.cp!(Path.join([tmp_dir, "package", "lightningcss"]), bin_path)
        File.write!(Path.join(Path.dirname(bin_path), "version"), version)
    end
  end

  defp fetch_body!(url) do
    scheme = URI.parse(url).scheme
    url = String.to_charlist(url)
    Logger.debug("Downloading lightning_css from #{url}")

    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    if proxy = proxy_for_scheme(scheme) do
      %{host: host, port: port} = URI.parse(proxy)
      Logger.debug("Using #{String.upcase(scheme)}_PROXY: #{proxy}")
      set_option = if "https" == scheme, do: :https_proxy, else: :proxy
      :httpc.set_options([{set_option, {{String.to_charlist(host), port}, []}}])
    end

    # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
    cacertfile = cacertfile() |> String.to_charlist()

    http_options =
      [
        ssl: [
          verify: :verify_peer,
          cacertfile: cacertfile,
          depth: 2,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ]
      |> maybe_add_proxy_auth(scheme)

    options = [body_format: :binary]

    case :httpc.request(:get, {url, []}, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body

      other ->
        raise """
        couldn't fetch #{url}: #{inspect(other)}

        You may also install the "lightning_css" executable manually, \
        see the docs: https://hexdocs.pm/lightning_css
        """
    end
  end

  defp proxy_for_scheme("http") do
    System.get_env("HTTP_PROXY") || System.get_env("http_proxy")
  end

  defp proxy_for_scheme("https") do
    System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")
  end

  defp maybe_add_proxy_auth(http_options, scheme) do
    case proxy_auth(scheme) do
      nil -> http_options
      auth -> [{:proxy_auth, auth} | http_options]
    end
  end

  defp proxy_auth(scheme) do
    with proxy when is_binary(proxy) <- proxy_for_scheme(scheme),
         %{userinfo: userinfo} when is_binary(userinfo) <- URI.parse(proxy),
         [username, password] <- String.split(userinfo, ":") do
      {String.to_charlist(username), String.to_charlist(password)}
    else
      _ -> nil
    end
  end


  defp freshdir_p(path) do
    with {:ok, _} <- File.rm_rf(path),
         :ok <- File.mkdir_p(path) do
      path
    else
      _ -> nil
    end
  end

  defp cacertfile() do
    Application.get_env(:lightning_css, :cacerts_path) || CAStore.file_path()
  end
end
