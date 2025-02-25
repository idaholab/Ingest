defmodule Ingest.Vault do
  use Cloak.Vault, otp_app: :ingest
end

defmodule Ingest.Encrypted.Binary do
  use Cloak.Ecto.Binary, vault: Ingest.Vault
end
