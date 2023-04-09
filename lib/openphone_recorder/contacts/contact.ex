defmodule OpenphoneRecorder.Contacts.Contact do
  use Ecto.Schema
  import Ecto.Changeset

  schema "contacts" do
    field :external_id, :string
    field :full_name, :string
    field :source, Ecto.Enum, values: [:openphone]

    timestamps()
  end

  @doc false
  def changeset(contact, attrs) do
    contact
    |> cast(attrs, [:full_name, :external_id, :source])
    |> validate_required([:full_name, :external_id, :source])
  end
end
