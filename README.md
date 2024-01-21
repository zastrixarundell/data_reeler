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

### Splash

To be able to load dynamic JavaScript content [Splash](https://hub.docker.com/r/scrapinghub/splash/) needs to be used. Also for extra security `podman` is used instead of `docker`.

To start splash run the command:

```bash
podman run --name splash -d -p 8050:8050 scrapinghub/splash 
```

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
