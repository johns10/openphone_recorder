defmodule Mix.Tasks.AssignContactIdToParticipant do
  @moduledoc "This task attempts to assign contact id's to participants"
  use Mix.Task

  import Ecto.Query
  alias Discussit.Contacts
  alias Discussit.Participants
  alias Discussit.Participants.Participant
  alias Discussit.Repo

  def run(_) do
    Application.ensure_all_started(:discussit)

    query =
      from(p in Participant,
        where: not is_nil(p.phone_number_id)
      )

    stream = Repo.stream(query)

    Repo.transaction(fn ->
      Enum.map(stream, fn %{phone_number_id: phone_number_id} = participant ->
        Contacts.list_contacts(filters: [phone_number_id: phone_number_id])
        |> case do
          [] ->
            nil

          [contact] ->
            Task.start(fn ->
              Participants.update_participant(participant, %{contact_id: contact.id})
            end)

          [_contact | _] ->
            nil
        end
      end)
    end)
  end
end
