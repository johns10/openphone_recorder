defmodule OpenphoneRecorder.Participants do
  import Ecto.Query, warn: false
  alias OpenphoneRecorder.Repo

  alias OpenphoneRecorder.Participants.Participant

  def list_participants do
    Repo.all(Participant)
  end

  def get_participant!(id), do: Repo.get!(Participant, id)

  def create_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
  end

  @duplicate_participant_error [conversation_id: {"has already been taken", [constraint: :unique, constraint_name: "participants_conversation_id_phone_number_id_index"]}]

  def upsert_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, _} = result -> result
      {:error, %{changes: changes, errors: @duplicate_participant_error}} ->
        {:ok, Repo.get_by(Participant, changes)}
    end
  end

  def update_participant(%Participant{} = participant, attrs) do
    participant
    |> Participant.changeset(attrs)
    |> Repo.update()
  end

  def delete_participant(%Participant{} = participant) do
    Repo.delete(participant)
  end

  def change_participant(%Participant{} = participant, attrs \\ %{}) do
    Participant.changeset(participant, attrs)
  end
end
