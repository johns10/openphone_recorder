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
  alias Discussit.Contacts

  alias Discussit.Events.Openphone.CallCompleted
  alias Discussit.Events.Openphone.CallRinging
  alias Discussit.Events.Openphone.CallRecordingCompleted

  alias Discussit.Events.Openphone.MessageReceived
  alias Discussit.Events.Openphone.MessageDelivered

  alias Discussit.Events.Openphone.ContactUpdated

  alias Discussit.Events.Openphone.Data.Call
  alias Discussit.Events.Openphone.Data.Media

  def reproject_event(external_id) do
    [filters: [external_id: external_id]]
    |> Discussit.Events.list_events()
    |> Enum.map(fn %{payload: payload, account_id: account_id} ->
      event = Discussit.Events.cast_event(payload)
      __MODULE__.apply(event, account_id)
    end)
  end

  def apply(%CallRinging{data: openphone_call}, account_id) do
    with {:ok, data} <- prepare_model(openphone_call, account_id),
         call_attrs <- Calls.Call.cast_openphone_call(openphone_call, data),
         {:ok, call} <- Calls.upsert_call(call_attrs) do
      {:ok, call}
    end
  end

  def apply(%CallCompleted{data: openphone_call}, account_id) do
    with {:ok, data} <- prepare_model(openphone_call, account_id),
         {:ok, voicemail} <- handle_upload(openphone_call, account_id),
         call_attrs <-
           Calls.Call.cast_openphone_call(openphone_call, data, %{voicemail: voicemail}),
         {:ok, call} <- Calls.upsert_call(call_attrs) do
      {:ok, call}
    end
  end

  def apply(%CallRecordingCompleted{data: openphone_call}, account_id) do
    with {:ok, data} <- prepare_model(openphone_call, account_id),
         {:ok, recording} <- handle_upload(openphone_call, account_id),
         call_attrs <-
           Calls.Call.cast_openphone_call(openphone_call, data, %{call_recording: recording}),
         {:ok, call} <- Calls.upsert_call(call_attrs) do
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
         {:ok, %{phone_numbers: phone_numbers}} <-
           PhoneNumbers.upsert_all_phone_numbers(contact_attrs.phone_numbers),
         cpn_attrs <- Enum.map(phone_numbers, &%{phone_number_id: &1.id, contact_id: contact.id}),
         {:ok, %{contact_phone_numbers: _contact_phone_numbers}} <-
           ContactPhoneNumbers.get_or_insert_all_contact_phone_number(cpn_attrs) do
      {:ok, Contacts.get_contact!(contact.id, preloads: [:phone_numbers])}
    end
  end

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
           }),
         {:ok, from_participant} <- resolve_contact(from_participant, from_phone_number),
         {:ok, to_participant} <- resolve_contact(to_participant, to_phone_number) do
      {:ok,
       %{
         from_participant: from_participant,
         to_participant: to_participant,
         conversation: conversation
       }}
    end
  end

  defp resolve_contact(%{contact_id: nil} = participant, phone_number) do
    contact_id =
      Contacts.list_contacts(filters: [phone_number_id: phone_number.id])
      |> case do
        [] -> nil
        [contact] -> contact.id
        [_ | _] -> nil
      end

    Participants.update_participant(participant, %{contact_id: contact_id})
  end

  defp resolve_contact(participant, _), do: {:ok, participant}

  defp handle_upload(
         %Call{id: id, voicemail: %Media{duration: d, type: "audio/mpeg"} = media},
         account_id
       )
       when d > 0,
       do: transfer_file(id, media, :voicemail, account_id)

  defp handle_upload(
         %Call{id: id, media: [%Media{duration: d, type: "audio/mpeg"} = media]},
         account_id
       )
       when d > 0,
       do: transfer_file(id, media, :call_recording, account_id)

  defp handle_upload(_, _), do: {:ok, nil}

  defp transfer_file(id, %Media{url: media_url} = media, _type, _account_id) do
    bucket = Application.get_env(:discussit, :bucket)
    object_path = "/recordings/#{Calls.Call.id(:openphone, id)}"

    with {:ok, path} = Briefly.create(),
         {:ok, %{status_code: 200, body: body}} <- HTTP.get(media_url),
         :ok <- File.write(path, body),
         request = ExAws.S3.put_object(bucket, object_path, File.read!(path)),
         {:ok, _response} <- ExAws.request(request) do
      {:ok, %{bucket: bucket, key: object_path, metadata: Map.from_struct(media)}}
    end
  end
end
