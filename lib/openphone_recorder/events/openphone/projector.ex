defmodule OpenphoneRecorder.Events.Openphone.Projector do
  @moduledoc """
  Here is some test markdown
  """
  require Logger

  alias OpenphoneRecorder.Statements
  alias OpenphoneRecorder.Statements.Statement
  alias OpenphoneRecorder.HTTP
  alias OpenphoneRecorder.PhoneNumbers
  alias OpenphoneRecorder.Conversations
  alias OpenphoneRecorder.Participants
  alias OpenphoneRecorder.Calls
  alias OpenphoneRecorder.Openai
  alias OpenphoneRecorder.Audio
  alias OpenphoneRecorder.Contacts

  alias OpenphoneRecorder.Events.Openphone.CallCompleted
  alias OpenphoneRecorder.Events.Openphone.CallRinging
  alias OpenphoneRecorder.Events.Openphone.CallRecordingCompleted

  alias OpenphoneRecorder.Events.Openphone.MessageReceived
  alias OpenphoneRecorder.Events.Openphone.MessageDelivered

  alias OpenphoneRecorder.Events.Openphone.ContactCreated

  alias OpenphoneRecorder.Events.Openphone.Data.Call
  alias OpenphoneRecorder.Events.Openphone.Data.Media

  def apply(%CallRinging{data: openphone_call}) do
    with {:ok, data} <- prepare_model(openphone_call),
         call_attrs <- Calls.Call.cast_openphone_call(openphone_call, data.conversation.id),
         {:ok, call} <- Calls.upsert_call(call_attrs) do
      {:ok, call}
    end
  end

  def apply(%CallCompleted{data: openphone_call}) do
    with {:ok, data} <- prepare_model(openphone_call),
         call_attrs <- Calls.Call.cast_openphone_call(openphone_call, data.conversation.id),
         {:ok, call} <- Calls.upsert_call(call_attrs),
         {:ok, call} <- maybe_transcribe_voicemail(openphone_call, call, data.from_participant) do
      {:ok, call}
    end
  end

  def apply(%CallRecordingCompleted{data: openphone_call}) do
    with {:ok, data} <- prepare_model(openphone_call),
         call_attrs <- Calls.Call.cast_openphone_call(openphone_call, data.conversation.id),
         {:ok, call} <- Calls.upsert_call(call_attrs),
         {:ok, call} <- maybe_transcribe_call_recording(call, openphone_call, data) do
      {:ok, call}
    end
  end

  def apply(%MessageReceived{data: message}) do
    with {:ok, data} <- prepare_model(message),
         statement_attrs <- Statement.cast_openphone_message(message, data.conversation.id) do
      Statements.upsert_statement(statement_attrs)
    end
  end

  def apply(%MessageDelivered{data: message}) do
    with {:ok, data} <- prepare_model(message),
         statement_attrs <- Statement.cast_openphone_message(message, data.conversation.id) do
      Statements.upsert_statement(statement_attrs)
    end
  end

  def apply(%ContactCreated{data: contact}) do
    with contact_attrs <- Contacts.Contact.cast_openphone_contact(contact),
         {:ok, contact} <- Contacts.create_contact(contact_attrs) do
      {:ok, contact}
    end
  end

  def prepare_model(%{
        to: to_phone_number,
        from: from_phone_number,
        conversation_id: external_conversation_id
      }) do
    from_phone_number_attrs = %{
      phone_number: from_phone_number,
      source: :openphone
    }

    to_phone_number_attrs = %{
      phone_number: to_phone_number,
      source: :openphone
    }

    conversation_attrs = %{
      external_id: external_conversation_id,
      source: :openphone
    }

    with {:ok, from_phone_number} <- PhoneNumbers.upsert_phone_number(from_phone_number_attrs),
         {:ok, to_phone_number} <- PhoneNumbers.upsert_phone_number(to_phone_number_attrs),
         {:ok, conversation} <- Conversations.upsert_conversation(conversation_attrs),
         {:ok, from_participant} <-
           Participants.upsert_participant(%{
             conversation_id: conversation.id,
             phone_number_id: from_phone_number.id
           }),
         {:ok, to_participant} <-
           Participants.upsert_participant(%{
             conversation_id: conversation.id,
             phone_number_id: to_phone_number.id
           }) do
      {:ok,
       %{
         from_participant: from_participant,
         to_participant: to_participant,
         conversation: conversation
       }}
    end
  end

  defp maybe_transcribe_voicemail(
         %Call{voicemail: %Media{duration: duration, type: "audio/mpeg", url: url}},
         call,
         participant
       )
       when duration > 0 do
    with {:ok, path} = Briefly.create(extname: ".mp3"),
         {:ok, %{status_code: 200, body: body}} <- HTTP.get(url),
         :ok <- File.write(path, body),
         {:ok, %{status_code: 200, body: body}} <- Openai.create_transcript(%{file: path}),
         {:ok, %{"text" => text, "duration" => duration}} <-
           Jason.decode(body) do
      %{
        content: text,
        occurred_at:
          call.completed_at
          |> DateTime.add(-1 * cast_microseconds(duration), :microsecond),
        type: :voicemail,
        conversation_id: call.conversation_id,
        participant_id: participant.id,
        call_id: call.id
      }
      |> Statements.create_statement()
      |> case do
        {:ok, statement} ->
          {:ok, Map.put(call, :statements, [statement])}

        error ->
          error
      end
    end
  end

  defp maybe_transcribe_voicemail(_openphone_call, call, _participant), do: {:ok, call}

  defp maybe_transcribe_call_recording(
         call,
         %Call{media: [%Media{duration: duration, type: "audio/mpeg", url: media_url}]},
         %{from_participant: from_participant, to_participant: to_participant}
       )
       when duration > 0 do
    with {:ok, path} = Briefly.create(extname: ".mp3"),
         {:ok, %{status_code: 200, body: body}} <- HTTP.get(media_url),
         :ok <- File.write(path, body),
         {:ok, %{left: left, right: right}} <- Audio.split(path),
         {:ok, %{status_code: 200, body: left_body}} <- Openai.create_transcript(%{file: left}),
         {:ok, %{status_code: 200, body: right_body}} <- Openai.create_transcript(%{file: right}),
         {:ok, %{"duration" => duration, "segments" => left_segments}} <- Jason.decode(left_body),
         {:ok, %{"segments" => right_segments}} <- Jason.decode(right_body) do
      now = DateTime.utc_now()

      attrs =
        (right_segments ++ left_segments)
        |> Enum.map(fn segment ->
          %{
            occurred_at:
              call.completed_at
              |> DateTime.add(-1 * cast_microseconds(duration), :microsecond)
              |> DateTime.add(cast_microseconds(segment["start"]), :microsecond),
            type: :call,
            content: segment["text"],
            participant_id: from_participant.id,
            call_id: call.id,
            inserted_at: now,
            updated_at: now
          }
        end)

      changesets = Enum.map(attrs, &Statements.change_statement(%Statement{}, &1))

      changeset_errors =
        changesets
        |> Enum.reduce([], fn changeset, acc ->
          Ecto.Changeset.apply_action(changeset, :insert)
          |> case do
            {:ok, _} -> acc
            {:error, changeset} -> [changeset | acc]
          end
        end)

      case changeset_errors do
        [_ | _] = changeset_errors ->
          {:error, %{statements: changeset_errors}}

        list when list == [] ->
          {_result_count, statements} =
            OpenphoneRecorder.Repo.insert_all(Statement, attrs, returning: true)

          {:ok, Map.put(call, :statements, Enum.sort_by(statements, & &1.occurred_at))}
      end
    end
  end

  defp maybe_transcribe_call_recording(_openphone_call, call, _participants),
    do: {:ok, call}

  defp cast_microseconds(seconds), do: (seconds * 1_000_000) |> floor()
end
