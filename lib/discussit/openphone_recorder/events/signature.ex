defmodule Discussit.Events.Signature do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :signature, :string
  end

  def validate(signature, body, secret) do
    %__MODULE__{}
    |> cast(%{signature: signature}, [:signature])
    |> validate_required([:signature])
    |> validate_signature(body, secret)
    |> apply_action(:insert)
  end

  defp validate_signature(changeset, body, secret) do
    case get_change(changeset, :signature) do
      nil ->
        changeset

      incoming_signature ->
        signing_key_bytes = Base.decode64!(secret)

        case String.split(incoming_signature, ";") do
          [_, _, timestamp, provided_digest] ->
            signed_data = "#{timestamp}.#{body}"

            hmac_digest =
              :crypto.mac(:hmac, :sha256, signing_key_bytes, signed_data)
              |> Base.encode64()

            case provided_digest == hmac_digest do
              true -> changeset
              false -> add_error(changeset, :signature, "Signature not valid")
            end

          _ ->
            false
        end
    end
  end
end
