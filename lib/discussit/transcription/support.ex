defmodule Discussit.Transcription.Support do
  require Logger

  alias Discussit.Calls
  alias Discussit.Calls.Call
  alias Discussit.Meetings.Meeting
  alias Discussit.Meetings
  alias Discussit.Statements
  alias Discussit.Statements.Statement
  alias Discussit.Transcription.AssemblyAI

  @channel_mapping %{
    "1" => :left,
    "2" => :right
  }

  def get_data(id, type, opts \\ [])

  def get_data(id, %Meeting{}, opts) do
    with %Meeting{} = meeting <- Meetings.get_meeting!(id),
         {:ok, meeting} <- Meetings.update_meeting(meeting, %{projector_status: :in_progress}) do
      user_id = opts[:user_id] || raise("cannot send meeting updates without user id")

      DiscussitWeb.Endpoint.broadcast(
        "user_#{user_id}",
        "meeting_transcription_progress",
        meeting |> Map.put(:statements, [])
      )

      %{
        data: meeting,
        status: :ok,
        message: ""
      }
    else
      {:error, changeset} ->
        put_error(%{}, changeset_error_to_string(changeset))
    end
  end

  def prepare_files(%{data: %Meeting{files: files}} = state) do
    recordings =
      files
      |> Enum.filter(fn
        %{metadata: %{"type" => "audio/mp4"}} -> true
        _ -> false
      end)
      |> Enum.map(fn %{bucket: bucket, key: key} = file ->
        {:ok, url} =
          Discussit.Config.ex_aws_s3_config()
          |> ExAws.S3.presigned_url(:get, bucket, key)

        Map.put(file, :url, url)
      end)

    chat =
      Enum.find(files, fn
        %{name: "chat.txt"} -> true
        _ -> false
      end)
      |> case do
        nil ->
          nil

        %{bucket: bucket, key: key} = chat ->
          {:ok, url} =
            Discussit.Config.ex_aws_s3_config()
            |> ExAws.S3.presigned_url(:get, bucket, key)

          %{chat | url: url}
      end

    state
    |> Map.put(:recordings, recordings)
    |> Map.put(:chat, chat)
  end

  def prepare_files(%{data: %Call{voicemail: file, call_recording: nil}} = state),
    do: Map.put(state, :recordings, [put_presigned_url(file)])

  def prepare_files(%{data: %Call{voicemail: nil, call_recording: file}} = state),
    do: Map.put(state, :recordings, [put_presigned_url(file)])

  def prepare_files(%{status: :error} = state), do: state

  def put_presigned_url(%{bucket: bucket, key: key} = file) do
    {:ok, url} =
      Discussit.Config.ex_aws_s3_config()
      |> ExAws.S3.presigned_url(:get, bucket, key)

    Map.put(file, :url, url)
  end

  def start_transcribing(%{status: :ok, data: %Meeting{} = meeting, recordings: rs} = state) do
    opts = %{
      speaker_labels: true,
      webhook_url:
        "#{Discussit.Config.public_url()}/api/transcription/complete?meeting_id=#{meeting.id}"
    }

    with {:ok, transcript_ids} <- start_transcriptions(rs, opts),
         {:ok, meeting} <- Meetings.update_meeting(meeting, %{transcript_ids: transcript_ids}) do
      Map.put(state, :data, meeting)
    else
      _ ->
        state
        |> Map.put(:status, :error)
        |> Map.put(:error, "error starting transcription")
    end
  end

  def start_transcribing(%{status: :ok, data: %Call{} = call, recordings: recordings} = state) do
    opts = %{
      dual_channel: true,
      webhook_url:
        "#{Discussit.Config.public_url()}/api/transcription/complete?call_id=#{call.id}"
    }

    with {:ok, transcript_ids} <- start_transcriptions(recordings, opts),
         {:ok, call} <- Calls.update_call(call, %{transcript_ids: transcript_ids}) do
      Map.put(state, :data, call)
    else
      _ ->
        state
        |> Map.put(:status, :error)
        |> Map.put(:error, "error starting transcription")
    end
  end

  def start_transcribing(%{status: :error} = state), do: state

  defp start_transcriptions(recordings, opts) do
    Enum.reduce_while(recordings, {:ok, []}, fn %{url: url}, {:ok, acc} ->
      case AssemblyAI.start_transcription(url, opts) do
        {:ok, id} -> {:cont, {:ok, [id | acc]}}
        _ -> {:halt, {:error, acc}}
      end
    end)
  end

  def finish_transcribing(state, opts \\ [])

  def finish_transcribing(%{status: :ok, data: %{transcript_ids: ids}} = state, opts) do
    with {:ok, transcripts} <- await_transcription_results(ids, opts),
         {:ok, result} <- process_transcription_results(transcripts),
         %{segments: segments, duration: duration} <- result do
      state
      |> Map.put(:segments, segments)
      |> Map.put(:duration, duration)
      |> Map.put(
        :message,
        state.message <> "Found #{Enum.count(segments)} segments over #{duration}."
      )
    end
  end

  def finish_transcribing(%{status: :error} = state, _opts), do: state

  defp await_transcription_results(ids, opts) do
    transcripts =
      Enum.map(ids, fn id ->
        with {:ok, transcript} <- AssemblyAI.finish_transcription(id, opts) do
          transcript
        end
      end)

    {:ok, transcripts}
  end

  def process_transcription_results(transcripts) do
    {transcripts, duration} =
      Enum.map_reduce(transcripts, 0, fn transcript, acc ->
        %{duration: duration, segments: segments} = transcript

        segments =
          Enum.map(segments, fn %{"start" => start, "end" => end_time, "words" => words} = segment ->
            words =
              Enum.map(words, fn %{"start" => start, "end" => end_time} = word ->
                %{word | "start" => start + acc, "end" => end_time + acc}
              end)

            %{segment | "start" => start + acc, "end" => end_time + acc, "words" => words}
          end)

        {%{transcript | segments: segments}, acc + duration * 1000}
      end)

    segments = Enum.flat_map(transcripts, &Map.get(&1, :segments))

    {:ok, %{segments: segments, duration: duration}}
  end

  def build_statement_attrs(
        %{
          status: :ok,
          segments: segments,
          data: %Meeting{} = meeting
        } = state
      ) do
    %{occurred_at: occurred_at} = meeting
    now = NaiveDateTime.utc_now()
    alias Discussit.Participants

    participants =
      Enum.map(segments, & &1["speaker"])
      |> Enum.uniq()
      |> Enum.map(fn speaker_name ->
        {:ok, participant} =
          Participants.create_participant(%{name: speaker_name, meeting_id: meeting.id})

        {speaker_name, participant}
      end)
      |> Enum.into(%{})

    attrs =
      segments
      |> Enum.reject(&(&1["ignore"] == true))
      |> Enum.map(fn segment ->
        text = Map.get(segment, "text")
        %{segment: segment, attrs: Map.put(%{}, "content", text) |> Map.delete("text")}
      end)
      |> Enum.map(fn %{segment: segment} ->
        from = NaiveDateTime.add(occurred_at, segment["start"], :millisecond)

        to = NaiveDateTime.add(occurred_at, segment["end"], :millisecond)
        range = PgRanges.TsRange.new(from, to)

        participant = participants[segment["speaker"]]

        %{
          occurred_at: from,
          ts_range: range,
          content: segment["text"] |> String.trim(),
          participant_id: participant.id,
          meeting_id: meeting.id,
          inserted_at: now,
          updated_at: now,
          type: :meeting,
          source: :transcription,
          id: UUID.uuid4()
        }
      end)

    state
    |> Map.put(:statement_attrs, attrs)
    |> Map.put(:message, state.message <> "Put #{Enum.count(attrs)} attrs.  ")
  end

  def build_statement_attrs(
        %{
          status: :ok,
          segments: segments,
          data: %Call{conversation_id: conversation_id} = call,
          duration: duration
        } = state
      ) do
    %{
      from_channel: from_channel,
      to_channel: to_channel,
      from_participant_id: from_id,
      to_participant_id: to_id,
      answered_at: answered_at,
      completed_at: completed_at
    } = call

    now = NaiveDateTime.utc_now()

    start_time =
      answered_at ||
        NaiveDateTime.add(completed_at, -1 * cast_microseconds(duration), :microsecond)

    participants =
      Map.put(%{}, from_channel, from_id)
      |> Map.put(to_channel, to_id)

    attrs =
      segments
      |> Enum.reject(&(&1["ignore"] == true))
      |> Enum.map(fn segment ->
        attrs = Map.put(%{}, "content", Map.get(segment, "text")) |> Map.delete("text")
        %{segment: segment, attrs: attrs}
      end)
      |> Enum.map(fn %{segment: segment} ->
        from = NaiveDateTime.add(start_time, segment["start"], :millisecond)

        to = NaiveDateTime.add(start_time, segment["end"], :millisecond)
        range = PgRanges.TsRange.new(from, to)

        %{
          occurred_at: from,
          ts_range: range,
          content: segment["text"] |> String.trim(),
          participant_id: participants[@channel_mapping[segment["channel"]]],
          conversation_id: conversation_id,
          call_id: call.id,
          inserted_at: now,
          updated_at: now,
          source: :transcription,
          type: :call,
          id: UUID.uuid4()
        }
      end)

    state
    |> Map.put(:statement_attrs, attrs)
    |> Map.put(:message, state.message <> "Put #{Enum.count(attrs)} attrs.  ")
  end

  def build_statement_attrs(%{status: :error} = state), do: state

  def create_statements(%{status: :ok, statement_attrs: attrs} = state) do
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
        {_result_count, statements} = Discussit.Repo.insert_all(Statement, attrs, returning: true)

        sorted =
          Enum.sort(statements, &(NaiveDateTime.compare(&1.occurred_at, &2.occurred_at) != :gt))

        Map.put(state, :statements, sorted)
    end
  end

  def create_statements(%{status: :error} = state), do: state

  def update_data(state, opts \\ [])

  def update_data(%{data: %Meeting{} = meeting, statements: statements} = state, opts) do
    case Meetings.update_meeting(meeting, %{projector_status: :done}) do
      {:ok, meeting} -> %{state | data: meeting}
      {:error, _changeset} -> put_error(state, "failed to update call")
    end
  end

  def update_data(%{data: %Call{} = call} = state, _opts) do
    case Calls.update_call(call, %{status: :transcribed}) do
      {:ok, call} ->
        %{state | data: call}

      {:error, _changeset} ->
        put_error(state, "failed to update call")
    end
  end

  def update_data(%{status: :error} = state, _opts), do: state

  def prepare_return(%{data: data, statements: statements, message: message}) do
    Logger.info(message)
    Map.put(data, :statements, statements)
  end

  defp changeset_error_to_string(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.reduce("", fn {k, v}, acc ->
      joined_errors = Enum.join(v, "; ")
      "#{acc}#{k}: #{joined_errors}\n"
    end)
  end

  defp cast_microseconds(seconds), do: (seconds * 1_000_000) |> floor()

  defp put_error(state, message),
    do: state |> Map.put(:status, :error) |> Map.put(:error, message)
end
