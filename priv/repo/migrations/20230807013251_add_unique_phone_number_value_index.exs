defmodule Discussit.Repo.Migrations.AddUniquePhoneNumberValueIndex do
  use Ecto.Migration

  def change do
    create unique_index(:phone_numbers, [:value])
  end
end
