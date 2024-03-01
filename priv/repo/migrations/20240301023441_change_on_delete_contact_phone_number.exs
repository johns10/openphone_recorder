defmodule Discussit.Repo.Migrations.ChangeOnDeleteContactPhoneNumber do
  use Ecto.Migration

  def change do
    alter table(:contact_phone_numbers) do
      modify :phone_number_id, references(:phone_numbers, on_delete: :nilify_all, type: :uuid),
        from: references(:phone_numbers, on_delete: :nothing)

      modify :contact_id, references(:contacts, on_delete: :nilify_all, type: :uuid),
        from: references(:contact_id, on_delete: :nothing)
    end
  end
end
