FROM debian:stable-slim as builder

RUN apt update && apt upgrade -y -qq

RUN apt install -y \
    build-essential \
    git curl unzip \
    libncurses5-dev \
    libssl-dev

RUN useradd -ms $(which bash) user

WORKDIR /build

COPY .tool-versions .

USER user

RUN git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

ENV PATH="/home/user/.asdf/shims:/home/user/.asdf/bin:$PATH"

ENV MIX_ENV="prod"

RUN asdf plugin add erlang

RUN asdf plugin add elixir

RUN asdf install

COPY mix.exs .

COPY mix.lock .

USER root

RUN mkdir _build deps

RUN chown user:user _build deps mix.lock

RUN chmod 744 _build deps mix.lock

USER user

RUN mix deps.get

RUN mix deps.compile

COPY . .

RUN mix compile

ENTRYPOINT [ "mix" ]

CMD [ "phx.s" ]
