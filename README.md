# Ingest

Ingest is desisgned to be the upload point for various data management solutions in the DOE space and beyond. It takes the placed of Box and hopefully Globus both. With an emphasis on gathering metadata along with the actual data, we hope that this tool becomes a powerhouse for enabling experiments to extract and collect data from various groups and sources more easily than before.

## Requirements
- [asdf](https://asdf-vm.com/) - used for managing Elixir/Erlang/OTP versions so that you can keep this project separate from your main installations
- [asdf-elixir](https://github.com/asdf-vm/asdf-elixir) and [asdf-erlang](https://github.com/asdf-vm/asdf-erlang)
- [Mix](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html) - should be installed if you use asdf
- Postgres 14+
- *INL network or ZScaler Only* - you will need to download the CAINLROOT.cer from your certificate manager. This is needed for the common gotchas and getting setup steps below if you work behind a proxy, like INL does via ZScaler and their internal network

## Installation
1. Navigate to the root of the project and run `asdf install` - this will install all the toolchain and language dependencies needed locally. Optionally you may install these in the global space
2. Run `mix deps.get` & `mix deps.compile`
3. Install the `phx_new` generator - `mix archive.install hex phx_new`
4. Modify the configuration file in `config/dev.exs` - you will at least need to modify the database configuration to point to your local Postgres server.
5. Run `mix ecto.migrate` - this will run all the required migrations to setup your database.
6. If you're on VSCode you can use the default run configuration to run your application from the editor, or you may start your server by running `mix phx.server` in either your terminal or an iEX instance


## Common Problems and Solutions
- Mix can't find `rebar3` or fails to install `rebar3` via Hex: Download the [rebar3 binary](https://rebar3.org/) for your OS and put in a common location (`/usr/local/bin` for Unix systems). Then use this command to point Hex to `rebar3` - `mix local.rebar rebar3 path/to/rebar`
- CA Cert problems: Typically you'll see a failed `:httpc` library call and something about an unkown CA authority. The easier solution is to include an environment variable called `HEX_CACERTS_PATH` and set it to your root CA bundle. Another, less secure option, is to set `HEX_UNSAFE_HTTPS` to `1` and turn off SSL completely. Not recommended  


## Editor Setup
We recommend that you use either VSCode or Neovim for Elixir. 
[Setup for VSCode](https://fly.io/phoenix-files/setup-vscode-for-elixir-development/)
[Setup for NeoVim](https://elixirforum.com/t/neovim-elixir-setup-configuration-from-scratch-guide/46310)

## Running
To start your Phoenix server:

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
