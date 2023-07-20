defmodule Discussit.Events.Openphone.Data.PhoneNumber do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  embedded_schema do
    field :phone_number, :string
  end

  def changeset(call, params \\ %{}) do
    call
    |> cast(params, [:phone_number])
  end
end
