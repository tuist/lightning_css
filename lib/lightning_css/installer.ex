defmodule LightningCSS.Installer do
  require Logger

  @doc """
  Installs lightning_css with `configured_version/0`.
  """
  def install do
    version = LightningCSS.Versions.configured()
    tmp_opts = if System.get_env("MIX_XDG"), do: %{os: :linux}, else: %{}
    target = LightningCSS.Architectures.target()

    tmp_dir =
      freshdir_p(:filename.basedir(:user_cache, "lightning_css", tmp_opts)) ||
        freshdir_p(Path.join(System.tmp_dir!(), "lightning_css")) ||
        raise "could not install lightning_css. Set MIX_XGD=1 and then set XDG_CACHE_HOME to the path you want to use as cache"

    url =
      "https://registry.npmjs.org/lightningcss-cli-#{target}/-/lightningcss-cli-#{target}-#{version}.tgz"

    tar = fetch_body!(url)

    case :erl_tar.extract({:binary, tar}, [:compressed, cwd: to_charlist(tmp_dir)]) do
      :ok -> :ok
      other -> raise "couldn't unpack archive: #{inspect(other)}"
    end

    bin_path = LightningCSS.Paths.bin()
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
    cacertfile = LightningCSS.Paths.cacertfile() |> String.to_charlist()

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
end
