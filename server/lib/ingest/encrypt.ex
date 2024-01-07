defmodule Ingest.Vault do
  use Cloak.Vault, otp_app: :ingest
end

defmodule Ingest.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: Ingest.Vault

  # we override the default behavior here so that we can Base64 encode/decode the values to make sure they're json
  # compatible - without this, the encryption won't work
  def embed_as(:json), do: :dump

  def dump(nil), do: {:ok, nil}

  def dump(value) do
    with {:ok, encrypted} <- super(value) do
      {:ok, Base.encode64(encrypted)}
    end
  end

  def load(nil), do: {:ok, nil}

  def load(value), do: super(Base.decode64!(value))
end
