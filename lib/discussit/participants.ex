defmodule Discussit.Participants do
  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Participants.Participant

  def list_participants(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Participant
    |> maybe_filter_by_meeting_id(filters[:meeting_id])
    |> Repo.all()
  end

  def get_participant!(id), do: Repo.get!(Participant, id)

  defp maybe_filter_by_meeting_id(query, nil), do: query

  defp maybe_filter_by_meeting_id(query, meeting_id) do
    query
    |> where([p], p.meeting_id == ^meeting_id)
  end

  def create_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
  end

  @duplicate_participant_error [
    conversation_id:
      {"has already been taken",
       [
         constraint: :unique,
         constraint_name: "participants_conversation_id_phone_number_id_index"
       ]}
  ]

  def upsert_participants(attrs) do
    result =
      Enum.reduce(attrs, [], fn attrs, acc ->
        {:ok, participant} = upsert_participant(attrs)
        [participant | acc]
      end)

    {:ok, result}
  end

  def upsert_participant(attrs \\ %{}) do
    %Participant{}
    |> Participant.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, _} = result ->
        result

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
