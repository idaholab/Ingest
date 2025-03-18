# Note: This image needs to be build from the root folder
# since we include resources from the root folder
#
# docker build -t ingest -f ./server/Dockerfile
#
#
# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian
# instead of Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20230612-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.15.6-erlang-26.0.2-debian-bullseye-20230612-slim
#
ARG ELIXIR_VERSION=1.17.2
ARG OTP_VERSION=27.0.1
ARG DEBIAN_VERSION=bullseye-20240701-slim

ARG BUILDER_IMAGE="hexpm/elixir:1.17.2-erlang-27.0.1-debian-bullseye-20240701-slim"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM hexpm/elixir:1.17.2-erlang-27.0.1-debian-bullseye-20240701-slim as builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git nodejs npm curl unzip \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
  mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY ./mix.exs ./mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY ./config/config.exs ./config/prod.exs config/
RUN mix deps.compile

COPY priv priv
COPY lib lib
COPY assets assets

# compile assets
RUN cd assets && npm ci --progress=false --no-audit --loglevel=error

# fetch the sqlite3 extensions
RUN mix sqlite.fetch

RUN mix compile

RUN mix assets.deploy

# Changes to config/runtime.exs don't require recompiling the code
COPY ./config/runtime.exs config/

COPY ./rel rel

RUN mix release

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM debian:bullseye

RUN apt-get update -y \
  # UPDATE packages flag as vulernable
  && apt-get install -y libc6 perl tar openssl \
  # Install packages needed by application
  && apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*


# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

WORKDIR "/app"

COPY ./start.sh start.sh
RUN chmod +x start.sh

RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release and sqlite3 extensions from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/ingest ./

USER nobody

# If using an environment that doesn't automatically reap zombie processes, it is
# advised to add an init process such as tini via `apt-get install`
# above and adding an entrypoint. See https://github.com/krallin/tini for details
# ENTRYPOINT ["/tini", "--"]

ENTRYPOINT ["/app/start.sh"]