import Config

# Configure your database
config :data_reeler, DataReeler.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "data_reeler_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we can use it
# to bundle .js and .css sources.
config :data_reeler, DataReelerWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "xXuLkB5D7oBEs2Vp9PwgK7pneLUpv2c6eZTkYGQKVZRWlF7WJSvWBvvSHXu+vxKS",
  watchers: []
  
config :crawly,
  concurrent_requests_per_domain: 8,
  fetcher: {DataReeler.Fetchers.BrowserlessFetcher, [base_url: "http://localhost:3000/content?blockAds"]},
  pipelines: [
    DataReeler.Pipelines.ProductDatabase,
    Crawly.Pipelines.JSONEncoder
  ]
  
config :data_reeler, DataReeler.Elasticsearch.Cluster,
  # The URL where Elasticsearch is hosted on your system
  url: "http://localhost:9200",

  # If you want to mock the responses of the Elasticsearch JSON API
  # for testing or other purposes, you can inject a different module
  # here. It must implement the Elasticsearch.API behaviour.
  api: Elasticsearch.API.HTTP,

  # Customize the library used for JSON encoding/decoding.
  json_library: Jason, # or Jason

  # You should configure each index which you maintain in Elasticsearch here.
  # This configuration will be read by the `mix elasticsearch.build` task,
  # described below.
  indexes: %{
    # This is the base name of the Elasticsearch index. Each index will be
    # built with a timestamp included in the name, like "posts-5902341238".
    # It will then be aliased to "posts" for easy querying.
    products: %{
      # This file describes the mappings and settings for your index. It will
      # be posted as-is to Elasticsearch when you create your index, and
      # therefore allows all the settings you could post directly.
      settings: "priv/elasticsearch/products.json",

      # This store module must implement a store behaviour. It will be used to
      # fetch data for each source in each indexes' `sources` list, below:
      store: DataReeler.Elasticsearch.Store,

      # This is the list of data sources that should be used to populate this
      # index. The `:store` module above will be passed each one of these
      # sources for fetching.
      #
      # Each piece of data that is returned by the store must implement the
      # Elasticsearch.Document protocol.
      sources: [DataReeler.Stores.Product],

      # When indexing data using the `mix elasticsearch.build` task,
      # control the data ingestion rate by raising or lowering the number
      # of items to send in each bulk request.
      bulk_page_size: 5000,

      # Likewise, wait a given period between posting pages to give
      # Elasticsearch time to catch up.
      bulk_wait_interval: 15_000, # 15 seconds

      # By default bulk indexing uses the "create" action. To allow existing
      # documents to be replaced, use the "index" action instead.
      bulk_action: "create"
    }
  }

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Enable dev routes for dashboard and mailbox
config :data_reeler, dev_routes: true

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime
