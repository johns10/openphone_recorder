defmodule Discussit.Transcription.Support do
  require Logger

  alias Discussit.Calls
  alias Discussit.Calls.Call
  alias Discussit.Meetings.Meeting
  alias Discussit.Meetings
  alias Discussit.Tokens
  alias Discussit.Statements
  alias Discussit.Statements.Statement
  alias Discussit.Audio
  alias Discussit.Transcription.OpenAI
  alias Discussit.Transcription.AssemblyAI

  def get_data(id, type, opts \\ [])

  def get_data(id, %Meeting{}, opts) do
    with %Meeting{} = meeting <- Meetings.get_meeting!(id),
         {:ok, %{files: files} = meeting} <-
           Meetings.update_meeting(meeting, %{projector_status: :in_progress}) do
      user_id = opts[:user_id] || raise("cannot send meeting updates without user id")

      DiscussitWeb.Endpoint.broadcast(
        "user_#{user_id}",
        "meeting_transcription_progress",
        meeting |> Map.put(:statements, [])
      )

      recordings =
        Enum.filter(files, fn
          %{metadata: %{type: type}} when type in ["audio/mp4"] -> true
          _ -> false
        end)

      %{
        data: meeting,
        recordings: recordings,
        status: :ok,
        message: ""
      }
    else
      {:error, changeset} ->
        put_error(%{}, changeset_error_to_string(changeset))
    end
  end

  def get_data(%{call_id: id, conversation: conversation} = state, %Call{}, _opts) do
    with %Call{} = call <- Calls.get_call!(id),
         {:ok, call} <- Calls.update_call(call, %{status: :transcribing}) do
      DiscussitWeb.Endpoint.broadcast(
        Discussit.ConversationWorker.name(conversation) |> to_string(),
        "call_transcription_progress",
        call |> Map.put(:statements, [])
      )

      state
      |> Map.put(:data, call)
      |> Map.put(:status, :ok)
      |> Map.put(:message, "")
    else
      nil ->
        Map.put(state, :error, "call id does not exist")

      {:error, changeset} ->
        Map.put(state, :error, changeset_error_to_string(changeset))
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
          ExAws.Config.new(:s3)
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
            ExAws.Config.new(:s3)
            |> ExAws.S3.presigned_url(:get, bucket, key)

          %{chat | url: url}
      end

    state
    |> Map.put(:recordings, recordings)
    |> Map.put(:chat, chat)
  end

  def prepare_files(%{data: %Call{}} = state), do: state

  def prepare_files(%{status: :error} = state), do: state

  def transcribe(%{status: :ok, data: %Meeting{} = meeting, recordings: recordings} = state, opts) do
    {transcripts, duration} =
      Enum.map_reduce(recordings, 0, fn %{url: url}, acc ->
        with {:ok, %{duration: duration, segments: segments} = transcript} <-
               AssemblyAI.transcribe(url, opts) do
          segments =
            Enum.map(segments, fn %{"start" => start, "end" => end_time, "words" => words} =
                                    segment ->
              words =
                Enum.map(words, fn %{"start" => start, "end" => end_time} = word ->
                  %{word | "start" => start + acc, "end" => end_time + acc}
                end)

              %{segment | "start" => start + acc, "end" => end_time + acc, "words" => words}
            end)

          {%{transcript | segments: segments}, acc + duration * 1000}
        end
      end)

    segments = Enum.flat_map(transcripts, &Map.get(&1, :segments))
    {:ok, meeting} = Meetings.update_meeting(meeting, %{segments: segments})

    state
    |> Map.put(:segments, segments)
    |> Map.put(:duration, duration)
    |> Map.put(:meeting, meeting)
    |> Map.put(:type, :meeting)
    |> Map.put(
      :message,
      state.message <> "Found #{Enum.count(segments)} segments over #{duration}."
    )
  end

  def transcribe(
        %{status: :ok, data: %Call{voicemail: %{bucket: bucket, key: key}, call_recording: nil}} =
          state,
        opts
      ) do
    with {:ok, path} = Briefly.create(extname: ".mp3"),
         request = ExAws.S3.download_file(bucket, key, path),
         {:ok, :done} = ExAws.request(request),
         {:ok, duration} <- Audio.duration(path),
         {:ok, segments} <- OpenAI.transcribe(path, duration, opts) do
      state
      |> Map.put(:segments, segments)
      |> Map.put(:duration, duration)
      |> Map.put(:type, :voicemail)
      |> Map.put(
        :message,
        state.message <> "Found #{Enum.count(segments)} segments over #{duration}."
      )
    end
  end

  def transcribe(
        %{status: :ok, data: %Call{voicemail: nil, call_recording: %{bucket: bucket, key: key}}} =
          state,
        opts
      ) do
    with {:ok, path} = Briefly.create(extname: ".mp3"),
         request = ExAws.S3.download_file(bucket, key, path),
         {:ok, :done} = ExAws.request(request),
         {:ok, duration} <- Audio.duration(path),
         {:ok, %{left: left, right: right}} <- Audio.split(path),
         {:ok, left_segments} <- OpenAI.transcribe(left, duration, opts),
         {:ok, right_segments} <- OpenAI.transcribe(right, duration, opts) do
      segments =
        Enum.map(left_segments, &Map.put(&1, "channel", :left)) ++
          Enum.map(right_segments, &Map.put(&1, "channel", :right))

      state
      |> Map.put(:segments, segments)
      |> Map.put(:duration, duration)
      |> Map.put(:type, :call)
      |> Map.put(
        :message,
        state.message <> "Found #{Enum.count(segments)} segments over #{duration}.  "
      )
    else
      _ ->
        put_error(state, "failed to transcribe audio")
    end
  end

  def transcribe(%{status: :error} = state), do: state

  def ignore_segments(%{status: :ok, segments: segments} = state) do
    segments =
      Enum.map(segments, fn %{"text" => text} = segment ->
        text
        |> String.downcase()
        |> String.trim()
        |> String.replace(~r/[\p{P}\p{S}]/, "")
        |> Tokens.all_stopwords?()
        |> if(
          do: Map.put(segment, "ignore", true),
          else: segment
        )
      end)

    state
    |> Map.put(:segments, segments)
    |> Map.put(
      :message,
      state.message <>
        "Ignored #{segments |> Enum.filter(&(&1["ignore"] == true)) |> Enum.count()} segments.  "
    )
  end

  def ignore_segments(%{status: :error} = state), do: state

  def build_statement_attrs(
        %{
          status: :ok,
          segments: segments,
          data: %Meeting{} = meeting,
          type: type
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
        from = NaiveDateTime.add(occurred_at, segment["start"], :microsecond)

        to = NaiveDateTime.add(occurred_at, segment["end"], :microsecond)
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
          source: :transcription,
          type: type,
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
          data: %Call{} = call,
          duration: duration,
          type: type,
          conversation: conversation
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
        from = NaiveDateTime.add(start_time, cast_microseconds(segment["start"]), :millisecond)

        to = NaiveDateTime.add(start_time, cast_microseconds(segment["end"]), :millisecond)
        range = PgRanges.TsRange.new(from, to)

        %{
          occurred_at: from,
          ts_range: range,
          content: segment["text"] |> String.trim(),
          participant_id: participants[segment["channel"]],
          conversation_id: conversation.id,
          call_id: call.id,
          inserted_at: now,
          updated_at: now,
          source: :transcription,
          type: type,
          id: UUID.uuid4()
        }
      end)

    state
    |> Map.put(:statement_attrs, attrs)
    |> Map.put(:message, state.message <> "Put #{Enum.count(attrs)} attrs.  ")
  end

  def build_statement_attrs(%{status: :error} = state), do: state

  def group_statement_attrs(%{status: :ok, statement_attrs: attrs, data: %Meeting{}} = state) do
    Map.put(
      state,
      :message,
      state.message <> "No grouping on meetings, passed #{Enum.count(attrs)} attrs."
    )
  end

  def group_statement_attrs(%{status: :ok, statement_attrs: attrs, data: %Call{}} = state) do
    attrs =
      attrs
      |> Enum.sort(&(NaiveDateTime.compare(&1.occurred_at, &2.occurred_at) != :gt))
      |> Enum.group_by(& &1.participant_id)
      |> Enum.flat_map(fn {_participant_id, attrs} ->
        Enum.reduce(attrs, %{last: nil, results: []}, fn
          attr, %{last: nil} = state ->
            %{state | last: attr}

          this, %{last: last, results: results} = state ->
            case NaiveDateTime.diff(this.ts_range.lower, last.ts_range.upper) do
              diff when diff < 1 ->
                ts_range = PgRanges.TsRange.new(last.ts_range.lower, this.ts_range.upper)
                content = last.content <> " " <> this.content
                attrs = %{last | ts_range: ts_range, content: content}
                %{state | last: attrs}

              diff when diff >= 1 ->
                %{results: [last | results], last: this}
            end
        end)
        |> case do
          %{last: nil, results: results} -> results
          %{last: last, results: results} -> [last | results]
        end
      end)

    state
    |> Map.put(:statement_attrs, attrs)
    |> Map.put(:message, state.message <> "Grouped attrs into #{Enum.count(attrs)} groups.")
  end

  def group_statement_attrs(%{status: :error} = state), do: state

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
    user_id = opts[:user_id] || raise("cannot send meeting updates without user id")

    case Meetings.update_meeting(meeting, %{projector_status: :done}) do
      {:ok, meeting} ->
        DiscussitWeb.Endpoint.broadcast(
          "user_#{user_id}",
          "meeting_transcription_progress",
          meeting |> Map.put(:statements, statements)
        )

        %{state | data: meeting}

      {:error, _changeset} ->
        put_error(state, "failed to update call")
    end
  end

  def update_data(
        %{data: %Call{} = call, statements: statements, conversation: conversation} = state,
        _opts
      ) do
    case Calls.update_call(call, %{status: :transcribed}) do
      {:ok, call} ->
        DiscussitWeb.Endpoint.broadcast(
          Discussit.ConversationWorker.name(conversation) |> to_string(),
          "call_transcription_progress",
          call |> Map.put(:statements, statements)
        )

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
