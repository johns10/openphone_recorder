defmodule OpenphoneRecorder.Events.Openphone.Projector do
  require Logger

  alias OpenphoneRecorder.Statements
  alias OpenphoneRecorder.HTTP
  alias OpenphoneRecorder.PhoneNumbers
  alias OpenphoneRecorder.Conversations
  alias OpenphoneRecorder.Participants
  alias OpenphoneRecorder.Calls
  alias OpenphoneRecorder.Openai

  alias OpenphoneRecorder.Events.Openphone.CallCompleted
  alias OpenphoneRecorder.Events.Openphone.CallRinging
  alias OpenphoneRecorder.Events.Openphone.CallRecordingCompleted

  alias OpenphoneRecorder.Events.Openphone.MessageReceived
  alias OpenphoneRecorder.Events.Openphone.MessageDelivered

  alias OpenphoneRecorder.Events.Openphone.Data.Call
  alias OpenphoneRecorder.Events.Openphone.Data.Media

  def apply(%CallRinging{data: openphone_call}) do
    with {:ok, call} <- prepare_model(openphone_call) do
      {:ok, call}
    end
  end

  def apply(%CallCompleted{data: openphone_call}) do
    with {:ok, call} <- prepare_model(openphone_call) do
      {:ok, call}
    end
  end

  def apply(%CallRecordingCompleted{data: openphone_call}) do
    with {:ok, call} <- prepare_model(openphone_call) do
      {:ok, call}
    end
  end

  def apply(%MessageReceived{data: message}) do
    with {:ok, conversation} <- prepare_model(message) do
      IO.inspect(conversation)
    end
  end

  def prepare_model(
        %Call{
          to: to_phone_number,
          from: from_phone_number,
          conversation_id: external_conversation_id
        } = openphone_call
      ) do
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
         {:ok, _} <-
           Participants.upsert_participant(%{
             conversation_id: conversation.id,
             phone_number_id: to_phone_number.id
           }),
         call_attrs <- Calls.Call.cast_openphone_call(openphone_call, conversation.id),
         {:ok, call} <- Calls.upsert_call(call_attrs),
         {:ok, call} <- maybe_transcribe_voicemail(openphone_call, call, from_participant) do
      {:ok, call}
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
         {:ok, %{status_code: 200, body: body}} <-
           Openai.create_transcript(%{file: path}),
         {:ok, %{"text" => text, "duration" => duration}} <-
           Jason.decode(body) do
      %{
        content: text,
        occurred_at:
          call.completed_at
          |> DateTime.add(-1 * cast_milliseconds(duration), :millisecond),
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

  defp cast_milliseconds(seconds), do: (seconds * 100) |> floor()
end
