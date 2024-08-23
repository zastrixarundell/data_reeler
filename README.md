# data_reeler

A WebCrawler microservice for fishing stuff!

## Prerequisites for runtime

### Elixir

The specific version of Elixir and Erlang are set in the [.tool-versions](./.tool-versions) file. This can be done with [asdf](https://asdf-vm.com/). After following the asdf [instructions](https://asdf-vm.com/guide/getting-started.html) one can start adding the required plugins for the runtimes:

```bash
asdf plugin add elixir
asdf plugin add erlang
asdf install
```

After a few minute of compiling Erlang you should have elixir working:

```bash
$ elixir -v 
Erlang/OTP 26 [erts-14.2.1] [source] [64-bit] [smp:8:8] [ds:8:8:10] [async-threads:1] [jit:ns]

Elixir 1.16.0 (compiled with Erlang/OTP 24)
```

`CONCURRENT` is the amount of active connections. Generally 4 should be used per service, so just multiply the amount of services by 4 for this value.

`PREBOOT_QUANTITY` should *probably* be the amount of active chrome browsers at any time, although it might not work because of bad documentation.

### Elasticsearch

As this application uses elasticsearch for the main logic for filtering through the products, it needs to be ran as a service. Due to a bug of implementation in the ES library, elasticsearch 8 can't be used. To run the correct version in a container, run this command:

```bash
podman run --restart always -d --name elasticsearch --memory 2048m -p 0.0.0.0:9200:9200 -p 9300:9300 -e "discovery.type=single-node" -e "xpack.security.enabled=false" docker.elastic.co/elasticsearch/elasticsearch:7.17.18
```

To index/sync products onto the ES server, you need to run this command:

```bash
mix elasticsearch.build products --cluster DataReeler.Elasticsearch.Cluster
```

### Starting the crawlers

To start the crawlers, run this command:

`mix data_reeler.crawlers`

Or alternatively if `DECOUPLED_CRAWLERS` is set to `false`, it will run the crawlers with the application.

## Starting the server

  * Run `mix setup` to install and setup dependencies
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
