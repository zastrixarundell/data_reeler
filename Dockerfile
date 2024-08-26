FROM debian:stable as builder

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

COPY . .

USER root

RUN mkdir _build deps

RUN chown user:user _build deps mix.lock

RUN chmod 744 _build deps mix.lock

USER user

RUN mix deps.get

RUN mix deps.compile

RUN mix release prod

# Exit stage

FROM debian:stable-slim

RUN apt update

RUN apt upgrade -y -qq

RUN apt install -y libssl-dev

ENV CD_USER=user

RUN useradd -ms $(which bash) user

WORKDIR /app

COPY --from=builder /build/_build/prod/rel/prod .

USER $CD_USER

# ENV ELIXIR_ERL_OPTIONS="+fnu"

CMD ["/app/bin/prod", "start"]