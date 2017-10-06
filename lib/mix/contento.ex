defmodule Mix.Contento do
  require Logger

  import Mix.Generator

  alias Contento.New.{Git, Shell}

  @contento_repo "https://github.com/contentocms/contento.git"
  @default_theme_repo "https://github.com/contentocms/simplo.git"

  @doc """
  Clones Contento's repo into given destination.
  """
  def clone_contento(dest) do
    Git.clone_repo(@contento_repo, dest)
    :ok
  end

  @doc """
  Clones the default theme repo to `priv/themes` and installs it
  to Contento with `mix contento.install.theme [theme_alias]`

  This function expects to be run inside Contento's root directory.
  """
  def install_default_theme do
    with {:ok, _} <- Shell.cmd("mix", ["contento.install.theme", @default_theme_repo]),
      do: :ok
  end

  @doc """
  Creates a configuration file for both production and development
  environments, adapting some variables to match the current installation
  name.
  """
  def create_config_files(installation_name) do
    Logger.debug("Creating production configuration file...")

    prod_assigns = [name: installation_name,
                    endpoint_secret_key: random_string(),
                    guardian_secret_key: random_string()]

    "config"
    |> Path.join("prod.secret.exs")
    |> create_file(prod_config_template(prod_assigns))

    Logger.debug("Creating development configuration file...")

    dev_assigns = [name: installation_name,
                   guardian_secret_key: random_string()]

    "config"
    |> Path.join("dev.secret.exs")
    |> create_file(dev_config_template(dev_assigns))

    :ok
  end

  @doc """
  Installs and builds Contento back-office assets using `yarn`.

  This function expects to be run inside Contento's root directory.
  """
  def install_and_build_assets do
    File.cd!("assets", fn ->
      with {:ok, _} <- Shell.cmd("yarn", ["install"]),
           {:ok, _} <- Shell.cmd("yarn", ["build"]), do: :ok
    end)
  end

  @doc """
  Installs and compiles Contento dependencies.

  This function expects to be run inside Contento's root directory.
  """
  def fetch_and_compile_deps do
    with {:ok, _} <- Shell.cmd("mix", ["deps.get"]),
         {:ok, _} <- Shell.cmd("mix", ["deps.compile"]), do: :ok
  end

  @doc """
  Runs the following tasks inside Contento's root directory:

    $ mix ecto.create
    $ mix ecto.migrate
  """
  def create_db_and_migrate do
    with {:ok, _} <- Shell.cmd("mix", ["ecto.create"]),
         {:ok, _} <- Shell.cmd("mix", ["ecto.migrate"]), do: :ok
  end

  def setup do
    with {:ok, _} <- Shell.cmd("mix", ["contento.setup", "--defaults"]), do: :ok
  end

  defp random_string,
    do: :crypto.strong_rand_bytes(64) |> Base.encode64() |> binary_part(0, 64)

  embed_template :dev_config, """
  use Mix.Config

  # Configure Database
  config :contento, Contento.Repo,
    adapter: Ecto.Adapters.Postgres,
    username: "postgres",
    password: "postgres",
    database: "<%= @name %>_dev",
    hostname: "localhost",
    pool_size: 10

  # Configure Guardian
  config :contento, Contento.Guardian,
    issuer: "<%= @name %>_dev",
    secret_key: "<%= @guardian_secret_key %>"

  # Configure Bamboo
  config :contento, Contento.Mailer,
    adapter: Bamboo.LocalAdapter
  """

  embed_template :prod_config, """
  use Mix.Config

  # Configure Endpoint
  config :contento, ContentoWeb.Endpoint,
    secret_key_base: "<%= @endpoint_secret_key %>"

  # Configure Database
  config :contento, Contento.Repo,
    adapter: Ecto.Adapters.Postgres,
    username: "postgres",
    password: "postgres",
    database: "<%= @name %>_prod",
    hostname: "localhost",
    pool_size: 18

  # Configure Guardian
  config :contento, Contento.Guardian,
    issuer: "<%= @name %>_dev",
    secret_key: "<%= @guardian_secret_key %>"

  # Configure Bamboo
  config :contento, Contento.Mailer,
    adapter: Bamboo.SMTPAdapter,
    server: {:system, "SMTP_SERVER"},
    port: {:system, "SMTP_PORT"},
    username: {:system, "SMTP_USERNAME"},
    password: {:system, "SMTP_PASSWORD"},
    tls: :if_available, # can be `:always` or `:never`
    allowed_tls_versions: [:"tlsv1", :"tlsv1.1", :"tlsv1.2"],
    ssl: false, # can be `true`
    retries: 1
  """
end
