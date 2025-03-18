# Use an official Erlang image as the base
FROM elixir:1.18.3

# Install direnv

# Install dependencies and inotify-tools
RUN apt-get update && apt-get install -y curl git inotify-tools ca-certificates

# Copy the CA certificate from the context to the build container
# COPY CAINLROOT_B64.crt /usr/local/share/ca-certificates/
# ENV HEX_CACERTS_PATH=/usr/local/share/ca-certificates/CAINLROOT_B64.crt
# Update the CA certificates in the container
# RUN update-ca-certificates

# Install Node.js and npm
RUN apt-get install -y nodejs

# Set up project folder
ENV APP_HOME /app
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

# Install Hex and Rebar3
RUN mix local.hex --force && mix local.rebar --force