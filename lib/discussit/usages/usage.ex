defmodule Discussit.Usages.Usage do
  use Ecto.Schema
  import Ecto.Changeset
  alias Discussit.Accounts.Account

  schema "usages" do
    field :meta, :map

    field :model, Ecto.Enum,
      values: [
        "gpt-3.5-turbo": "gpt-3.5-turbo",
        "whisper-1": "whisper-1",
        assemblyai_default: "assemblyai_default"
      ]

    field :product, Ecto.Enum, values: [:chat_completions, :transcription]
    field :provider, Ecto.Enum, values: [:openai, :assemblyai]
    field :total, :float

    belongs_to :account, Account, type: :binary_id

    timestamps()
  end

  @doc false
  def changeset(usage, attrs) do
    usage
    |> cast(attrs, [:provider, :model, :product, :meta, :total, :account_id])
    |> validate_required([:account_id])
    |> foreign_key_constraint(:account_id)
    |> validate_required([:provider, :model, :product, :meta, :total])
  end
end
