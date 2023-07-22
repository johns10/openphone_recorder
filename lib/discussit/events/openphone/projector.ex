defmodule Discussit.Events.Openphone.Projector do
  @moduledoc """
  Here is some test markdown
  """
  require Logger

  alias Discussit.ContactPhoneNumbers
  alias Discussit.Statements
  alias Discussit.Statements.Statement
  alias Discussit.HTTP
  alias Discussit.PhoneNumbers
  alias Discussit.Conversations
  alias Discussit.Participants
  alias Discussit.Calls
  alias Discussit.Audio
  alias Discussit.Contacts

  alias Discussit.Events.Openphone.CallCompleted
  alias Discussit.Events.Openphone.CallRinging
  alias Discussit.Events.Openphone.CallRecordingCompleted

  alias Discussit.Events.Openphone.MessageReceived
  alias Discussit.Events.Openphone.MessageDelivered

  alias Discussit.Events.Openphone.ContactUpdated

  alias Discussit.Events.Openphone.Data.Call
  alias Discussit.Events.Openphone.Data.Media

  def apply(%CallRinging{data: openphone_call}, account_id) do
    with {:ok, data} <- prepare_model(openphone_call, account_id),
         call_attrs <- Calls.Call.cast_openphone_call(openphone_call, data.conversation.id),
         {:ok, call} <- Calls.upsert_call(call_attrs) do
      {:ok, call}
    end
  end

  def apply(%CallCompleted{data: openphone_call}, account_id) do
    with {:ok, data} <- prepare_model(openphone_call, account_id),
         call_attrs <- Calls.Call.cast_openphone_call(openphone_call, data.conversation.id),
         {:ok, call} <- Calls.upsert_call(call_attrs),
         {:ok, call} <- maybe_transcribe_voicemail(openphone_call, call, data.from_participant) do
      {:ok, call}
    end
  end

  def apply(%CallRecordingCompleted{data: openphone_call}, account_id) do
    with {:ok, data} <- prepare_model(openphone_call, account_id),
         call_attrs <- Calls.Call.cast_openphone_call(openphone_call, data.conversation.id),
         {:ok, call} <- Calls.upsert_call(call_attrs),
         {:ok, call} <- maybe_transcribe_call_recording(call, openphone_call, data) do
      {:ok, call}
    end
  end

  def apply(%MessageReceived{data: message}, account_id) do
    with {:ok, data} <- prepare_model(message, account_id),
         statement_attrs <- Statement.cast_openphone_message(message, data),
         {:ok, statement} <- Statements.upsert_statement(statement_attrs) do
      {:ok, statement}
    end
  end

  def apply(%MessageDelivered{data: message}, account_id) do
    with {:ok, data} <- prepare_model(message, account_id),
         statement_attrs <- Statement.cast_openphone_message(message, data),
         {:ok, statement} <- Statements.upsert_statement(statement_attrs) do
      {:ok, statement}
    end
  end

  def apply(%ContactUpdated{data: contact}, account_id) do
    with contact_attrs <- Contacts.Contact.cast_openphone_contact(contact, account_id),
         {:ok, contact} <- Contacts.upsert_contact(contact_attrs),
         phone_number_attrs <- phone_number_attrs(contact_attrs.phone_numbers, contact),
         {:ok, %{phone_numbers: phone_numbers}} <-
           PhoneNumbers.upsert_all_phone_numbers(phone_number_attrs),
         cpn_attrs <- Enum.map(phone_numbers, &%{phone_number_id: &1.id, contact_id: contact.id}),
         {:ok, %{contact_phone_numbers: _contact_phone_numbers}} <-
           ContactPhoneNumbers.get_or_insert_all_contact_phone_number(cpn_attrs) do
      {:ok, Contacts.get_contact!(contact.id, preload: [:phone_numbers])}
    end
  end

  defp phone_number_attrs(phone_numbers, %{id: id}),
    do: Enum.map(phone_numbers, &Map.put(&1, :contact_id, id))

  def prepare_model(
        %{
          to: to_phone_number,
          from: from_phone_number,
          conversation_id: external_conversation_id
        },
        account_id
      ) do
    from_phone_number_attrs = %{
      value: from_phone_number,
      source: :openphone
    }

    to_phone_number_attrs = %{
      value: to_phone_number,
      source: :openphone
    }

    conversation_attrs = %{
      account_id: account_id,
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
         %Call{
           voicemail: %Media{
             duration: duration,
             type: "audio/mpeg",
             url: url
           },
           created_at: created_at
         },
         %Calls.Call{conversation_id: conversation_id} = call,
         participant
       )
       when duration > 0 do
    opts = [model: "whisper-1", response_format: "verbose_json"]

    with {:ok, path} = Briefly.create(extname: ".mp3"),
         {:ok, %{status_code: 200, body: body}} <- HTTP.get(url),
         :ok <- File.write(path, body),
         {:ok, duration} <- Audio.duration(path),
         {:ok, %{text: text}} <- OpenAI.audio_transcription(path, opts) do
      %{
        content: text,
        occurred_at:
          (call.completed_at || created_at)
          |> NaiveDateTime.add(-1 * cast_microseconds(duration), :microsecond),
        type: :voicemail,
        conversation_id: conversation_id,
        participant_id: participant.id,
        call_id: call.id,
        source: :transcription,
        external_id: nil
      }
      |> Statements.upsert_statement()
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
         %Calls.Call{conversation_id: conversation_id} = call,
         %Call{media: [%Media{duration: duration, type: "audio/mpeg", url: media_url}]},
         %{from_participant: from_participant, to_participant: to_participant}
       )
       when duration > 0 do
    with {:ok, path} = Briefly.create(extname: ".mp3"),
         {:ok, %{status_code: 200, body: body}} <- HTTP.get(media_url),
         :ok <- File.write(path, body),
         {:ok, %{left: left, right: right}} <- Audio.split(path),
         {:ok, left_attrs} <- transcribe_file(left, from_participant, call, conversation_id),
         {:ok, right_attrs} <- transcribe_file(right, to_participant, call, conversation_id) do
      attrs = left_attrs ++ right_attrs
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
            Discussit.Repo.insert_all(Statement, attrs, returning: true)

          {:ok, Map.put(call, :statements, Enum.sort_by(statements, & &1.occurred_at))}
      end
    end
  end

  defp maybe_transcribe_call_recording(_openphone_call, call, _participants),
    do: {:ok, call}

  defp cast_microseconds(seconds), do: (seconds * 1_000_000) |> floor()

  defp transcribe_file(file, participant, call, conversation_id) do
    opts = [model: "whisper-1", response_format: "verbose_json"]

    with {:ok, %{duration: duration, segments: segments}} <-
           OpenAI.audio_transcription(file, opts) do
      now = NaiveDateTime.utc_now()

      {:ok,
       segments
       |> Enum.map(fn segment ->
         %{
           occurred_at:
             call.completed_at
             |> NaiveDateTime.add(-1 * cast_microseconds(duration), :microsecond)
             |> NaiveDateTime.add(cast_microseconds(segment["start"]), :microsecond),
           type: :call,
           content: segment["text"],
           participant_id: participant.id,
           conversation_id: conversation_id,
           call_id: call.id,
           inserted_at: now,
           updated_at: now,
           source: :transcription,
           id: UUID.uuid4()
         }
       end)}
    end
  end
end
