# `lightning_css`

<!-- MDOC !-->

[![Lightning CSS](https://github.com/glossia/lightning_css/actions/workflows/lightningcss.yml/badge.svg)](https://github.com/glossia/lightning_css/actions/workflows/lightningcss.yml)

`lightning_css` is an Elixir package to integrate [Lightning CSS](https://lightningcss.dev/) into an Elixir project.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `lightning_css` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:lightning_css, "~> 0.2.0"}
  ]
end
```

## Usage

After installing the package, you'll have to configure it in your project:

```elixir
# config/config.exs
config :lightning_css,
  version: "1.22.0",
  dev: [
    args: ~w(assets/foo.css --bundle --output-dir=static),
    watch_files: "assets/**/*.css",
    cd: Path.expand("../priv", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
```

### Configuration options

- **version:** Indicates the version that the package will download and use. When absent, it defaults to the value of `@latest_version` at [`lib/lightning_css.ex`](./lib/lightning_css.ex).
- **profiles:** Additional keys in the configuration keyword list represent profiles. Profiles are a combination of attributes the Lightning CSS can be executed with. You can indicate the profile to use when invoking the Mix task by using the `--profile` flag, for example `mix lightning_css --profile dev`. A profile is represented by a keyword list with the following attributes:
  - **args:** An list of strings representing the arguments that will be passed to the Lightning CSS executable.
  - **watch_files (optional):** A glob pattern that will be used when Lightning CSS is invoked with `--watch` to match the file changes against it.
  - **cd (optional):** The directory from where Lightning CSS is executed. When absent, it defaults to the project's root directory.
  - **env (optional):** A set of environment variables to make available to the Lightning CSS process.

### Phoenix

If you are using the Phoenix framework, we recommend doing an integration similar to the one Phoenix proposes by default for Tailwind and ESBuild.

After adding the dependency and configuring it as described above with at least one profile, adjust your app's endpoint configuration to add a new watcher:

```elixir
config :my_app, MyAppWeb.Endpoint,
  # ...other attributes
  watchers: [
    # :default is the name of the profile. Update it to match yours.
    css: {LightningCSS, :install_and_run, [:default, ~w(), watch: true]}
  ]
```

Then update the `aliases` of your project's `mix.exs` file:

```elixir
defp aliases do
  [
    # ...other aliases
    "assets.setup": [
      # ...other assets.setup tasks
      "lightning_css.install --if-missing"
    ],
    "assets.build": [
      # ...other assets.build tasks
      "lightning_css default",
    ],
    "assets.deploy": [
      # ...other deploy tasks
      "lightning_css default",
    ]
  ]
end
```
