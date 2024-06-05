# ObjectStorageAzure

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `object_storage_azure` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:object_storage_azure, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/object_storage_azure>.


## Testing
Must create a test container in azurite in order to be able to use it. Implement this.

```elixir
def create_container(%Container{} = container, %Config{} = config, prefix \\ nil) do
  {_request, response} =
    Req.Request.new(
      method: :put,
      url:
        if prefix do
          "#{build_base_url(config)}/#{URI.encode(container.name)}?restype=container"
        else
          "#{build_base_url(config)}/#{URI.encode(container.name)}?restype=container"
        end
    )
    |> sign(config)
    |> Req.Request.run_request()

  response.status
end

test "can create container" do
   {:ok, nil} =
     Container.new("test")
     |> Container.create_container(azurite_config())
end
```
