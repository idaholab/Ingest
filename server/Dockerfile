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

COPY ./azure_storage azure_storage

# prepare build dir
WORKDIR /app

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ENV MIX_ENV="prod"

# install mix dependencies
COPY ./server/mix.exs ./server/mix.lock ./
COPY ./server/apps/ingest/mix.exs  apps/ingest/mix.exs
COPY ./server/apps/ingest_web/mix.exs apps/ingest_web/mix.exs
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY ./server/config/config.exs ./server/config/prod.exs config/
RUN mix deps.compile

COPY ./server/apps/ingest_web/assets apps/ingest_web/assets

# fetch the sqlite3 extensions
RUN mix sqlite.fetch

RUN npm --prefix apps/ingest_web/assets ci --progress=false --no-audit --loglevel=error

# compile assets
RUN cd apps/ingest_web && mix assets.deploy

# Compile the release
COPY ./server/apps apps
RUN mix compile

# Changes to config/runtime.exs don't require recompiling the code
COPY ./server/config/runtime.exs config/

COPY ./server/rel rel

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

COPY ./server/start.sh start.sh
RUN chmod +x start.sh

RUN chown nobody /app

# set runner ENV
ENV MIX_ENV="prod"

# Only copy the final release and sqlite3 extensions from the build stage
COPY --from=builder --chown=nobody:root /app/_build/prod/rel/ingest_umbrella ./
COPY --from=builder --chown=nobody:root /app/apps/ingest/priv/sqlite_extensions /sqlite_extensions

USER nobody

# If using an environment that doesn't automatically reap zombie processes, it is
# advised to add an init process such as tini via `apt-get install`
# above and adding an entrypoint. See https://github.com/krallin/tini for details
# ENTRYPOINT ["/tini", "--"]


ENTRYPOINT ["/app/start.sh"]