import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :sso_server, SsoServer.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "sso_server_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sso_server, SsoServerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "Kkf+Gj8WMpfgY+NnC4ViLBOX5PDdrcIENBHFsQQ9udcVwJb6L6nW3Qt5QWwojjju",
  server: false

config :sso_server, :google_oauth,
  client_id: "test-client-id",
  client_secret: "test-client-secret",
  redirect_uri: "http://localhost:4002/auth/google/callback",
  base_url: System.get_env("OAUTH_MOCK_BASE_URL", "https://accounts.google.com")

# In test we don't send emails
config :sso_server, SsoServer.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
