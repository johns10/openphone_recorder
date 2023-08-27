defmodule Discussit.ConversationWorker.Impl do
  require Logger

  alias Discussit.ConversationSummarizers
  alias Discussit.ConversationSummarizers.ConversationSummarizer
  alias Discussit.Conversations.Conversation
  alias Discussit.Summarizers
  alias Discussit.Summarizers.Summarizer
  alias Discussit.DateSupport
  alias Discussit.Statements
  alias Discussit.Chunker
  alias Discussit.Summaries
  alias Discussit.Summaries.Summary
  alias Discussit.Summaries.Summarize
  alias Discussit.Calls
  alias Discussit.Calls.Call
  alias Discussit.Audio
  alias Discussit.Tokens
  alias Discussit.Statements.Statement

  def transcribe_call(call_ids, conversation, opts) do
    openai_config = Keyword.get(opts, :openai_config)

    call_ids
    |> Flow.from_enumerable()
    |> Flow.map(fn id ->
      # Sets the status fo the call, and casts call-related info
      state = %{id: id}

      with %Call{} = call <- Calls.get_call!(id),
           {:ok, call} <- Calls.update_call(call, %{status: :transcribing}) do
        {type, file} =
          case call do
            %{voicemail: nil, call_recording: file} -> {:call, file}
            %{voicemail: file, call_recording: nil} -> {:voicemail, file}
          end

        DiscussitWeb.Endpoint.broadcast(
          name(conversation) |> to_string(),
          "call_transcription_progress",
          call |> Map.put(:statements, [])
        )

        state
        |> Map.put(:call, call)
        |> Map.put(:file, file)
        |> Map.put(:type, type)
        |> Map.put(:status, :ok)
        |> Map.put(:message, "")
      else
        nil ->
          Map.put(state, :error, "call id does not exist")

        {:error, changeset} ->
          Map.put(state, :error, changeset_error_to_string(changeset))
      end
    end)
    |> Flow.map(fn
      # downloads the file and gets the transcription
      %{status: :ok, type: :voicemail, file: %{bucket: bucket, key: key}} = state ->
        opts = [model: "whisper-1", response_format: "verbose_json"]

        with {:ok, path} = Briefly.create(extname: ".mp3"),
             request = ExAws.S3.download_file(bucket, key, path),
             {:ok, :done} = ExAws.request(request),
             {:ok, duration} <- Audio.duration(path),
             {:ok, %{segments: segments}} <- OpenAI.audio_transcription(path, opts, openai_config) do
          state
          |> Map.put(:segments, segments)
          |> Map.put(:duration, duration)
          |> Map.put(
            :message,
            state.message <> "Found #{Enum.count(segments)} segments over #{duration}."
          )
        end

      %{status: :ok, type: :call, file: %{bucket: bucket, key: key}} = state ->
        opts = [model: "whisper-1", response_format: "verbose_json"]

        with {:ok, path} = Briefly.create(extname: ".mp3"),
             request = ExAws.S3.download_file(bucket, key, path),
             {:ok, :done} = ExAws.request(request),
             {:ok, duration} <- Audio.duration(path),
             {:ok, %{left: left, right: right}} <- Audio.split(path),
             {:ok, %{segments: left_segments}} <-
               OpenAI.audio_transcription(left, opts, openai_config),
             {:ok, %{segments: right_segments}} <-
               OpenAI.audio_transcription(right, opts, openai_config) do
          segments =
            Enum.map(left_segments, &Map.put(&1, "channel", :left)) ++
              Enum.map(right_segments, &Map.put(&1, "channel", :right))

          state
          |> Map.put(:segments, segments)
          |> Map.put(:duration, duration)
          |> Map.put(
            :message,
            state.message <> "Found #{Enum.count(segments)} segments over #{duration}.  "
          )
        else
          _ ->
            put_error(state, "failed to transcribe audio")
        end

      state ->
        state
    end)
    |> Flow.map(fn
      # Modifies the segments
      %{status: :ok, segments: segments} = state ->
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

      state ->
        state
    end)
    |> Flow.map(fn
      %{status: :ok, segments: segments, call: call, duration: duration, type: type} = state ->
        # Builds the attrs
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

        segments
        |> Enum.reject(&(&1["ignore"] == true))
        |> Enum.count()

        attrs =
          segments
          |> Enum.reject(&(&1["ignore"] == true))
          |> Enum.map(fn segment ->
            attrs = Map.put(%{}, "content", Map.get(segment, "text")) |> Map.delete("text")
            %{segment: segment, attrs: attrs}
          end)
          |> Enum.map(fn %{segment: segment} ->
            from =
              NaiveDateTime.add(start_time, cast_microseconds(segment["start"]), :microsecond)

            to = NaiveDateTime.add(start_time, cast_microseconds(segment["end"]), :microsecond)
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

      state ->
        state
    end)
    |> Flow.map(fn
      # Groups the statement attrs
      %{status: :ok, statement_attrs: attrs} = state ->
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

      state ->
        state
    end)
    |> Flow.map(fn
      # creates the statements
      %{status: :ok, statement_attrs: attrs} = state ->
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

            Map.put(state, :statements, statements)
        end

      state ->
        state
    end)
    |> Flow.map(fn
      %{call: call, statements: statements} = state ->
        case Calls.update_call(call, %{status: :transcribed}) do
          {:ok, call} ->
            DiscussitWeb.Endpoint.broadcast(
              name(conversation) |> to_string(),
              "call_transcription_progress",
              call |> Map.put(:statements, statements)
            )

            %{state | call: call}

          {:error, _changeset} ->
            put_error(state, "failed to update call")
        end

      state ->
        state
    end)
    |> Enum.map(fn
      %{call: call, statements: statements, message: message} ->
        Logger.info(message)

        sorted =
          Enum.sort(statements, &(NaiveDateTime.compare(&1.occurred_at, &2.occurred_at) != :gt))

        Map.put(call, :statements, sorted)

      state ->
        state
    end)
  end

  defp put_error(state, message),
    do: state |> Map.put(:status, :error) |> Map.put(:error, message)

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

  def create_daily_summaries(
        %ConversationSummarizer{
          conversation: %Conversation{} = conversation,
          summarizer: %Summarizer{} = summarizer
        } = conversation_summarizer,
        opts
      ) do
    opts = Summarize.cast_opts(opts, conversation_summarizer)

    Statements.list_statements(
      filters: [
        conversation_id: conversation.id,
        not_summarizer_id: summarizer.id,
        before: DateSupport.start_of_today(opts)
      ],
      preloads: [
        participant: [:phone_number, :contact]
      ],
      order_by: [occurred_at: :asc]
    )
    |> Chunker.apply(opts)
    |> Summarize.map_summarize(opts)
    |> Enum.map(&Map.put(&1, :conversation_summarizer, conversation_summarizer))
  end

  def create_weekly_summaries(
        %ConversationSummarizer{
          conversation: %Conversation{} = conversation,
          summarizer: %Summarizer{}
        } = conversation_summarizer,
        opts
      ) do
    opts = Summarize.cast_opts(opts, conversation_summarizer)

    case Summaries.get_latest_summary!(conversation.id, Summary.weekly()) do
      nil ->
        [
          order_by: [summary_interval_lower: :asc],
          filters: [
            level: Summary.daily(),
            conversation_id: conversation.id,
            before: DateSupport.beginning_of_week(NaiveDateTime.utc_now(), opts)
          ]
        ]

      %Summary{summary_interval: %{upper: upper}} ->
        [
          order_by: [summary_interval_lower: :asc],
          filters: [
            level: Summary.daily(),
            after: upper,
            before: DateSupport.beginning_of_week(NaiveDateTime.utc_now(), opts),
            conversation_id: conversation.id
          ]
        ]
    end
    |> Summaries.list_summaries()
    |> Chunker.apply(opts)
    |> Summarize.map_summarize(opts)
    |> Enum.map(&Map.put(&1, :conversation_summarizer, conversation_summarizer))
  end

  def create_monthly_summaries(
        %ConversationSummarizer{
          conversation: %Conversation{} = conversation,
          summarizer: %Summarizer{}
        } = conversation_summarizer,
        opts
      ) do
    opts = Summarize.cast_opts(opts, conversation_summarizer)

    case Summaries.get_latest_summary!(conversation.id, Summary.monthly()) do
      nil ->
        [
          order_by: [summary_interval_lower: :asc],
          filters: [
            level: Summary.daily(),
            conversation_id: conversation.id,
            before: DateSupport.beginning_of_month(NaiveDateTime.utc_now(), opts)
          ]
        ]

      %Summary{summary_interval: %{upper: upper}} ->
        [
          order_by: [summary_interval_lower: :asc],
          filters: [
            level: Summary.daily(),
            after: upper,
            before: DateSupport.beginning_of_month(NaiveDateTime.utc_now(), opts),
            conversation_id: conversation.id
          ]
        ]
    end
    |> Summaries.list_summaries()
    |> Chunker.apply(opts)
    |> Summarize.map_summarize(opts)
    |> Enum.map(&Map.put(&1, :conversation_summarizer, conversation_summarizer))
  end

  def create_yearly_summaries(
        %ConversationSummarizer{
          conversation: %Conversation{} = conversation,
          summarizer: %Summarizer{}
        } = conversation_summarizer,
        opts
      ) do
    opts = Summarize.cast_opts(opts, conversation_summarizer)

    case Summaries.get_latest_summary!(conversation.id, Summary.yearly()) do
      nil ->
        [
          filters: [
            level: Summary.monthly(),
            conversation_id: conversation.id,
            before: DateSupport.beginning_of_month(NaiveDateTime.utc_now(), opts)
          ]
        ]

      %Summary{summary_interval: %{upper: upper}} ->
        [
          filters: [
            level: Summary.weekly(),
            after: upper,
            before: DateSupport.beginning_of_month(NaiveDateTime.utc_now(), opts),
            conversation_id: conversation.id
          ]
        ]
    end
    |> Summaries.list_summaries()
    |> Chunker.apply(opts)
    |> Summarize.map_summarize(opts)
    |> Enum.map(&Map.put(&1, :conversation_summarizer, conversation_summarizer))
  end

  def ensure_conversation_summarizers_exist(%{conversation: conversation}) do
    ["daily", "weekly", "monthly", "yearly"]
    |> Enum.map(&Summarizers.get_summarizer_by!(name: &1))
    |> Enum.map(
      &%{
        s: &1,
        cs:
          ConversationSummarizers.get_conversation_summarizer_by(%{
            conversation_id: conversation.id,
            summarizer_id: &1.id
          })
      }
    )
    |> Enum.map(fn
      %{cs: nil, s: %{id: summarizer_id} = summarizer} ->
        ConversationSummarizers.create_conversation_summarizer(%{
          summarizer_id: summarizer_id,
          conversation_id: conversation.id
        })
        |> case do
          {:ok, cs} -> load(cs, conversation, summarizer)
          {:error, _} -> :error
        end

      %{cs: %ConversationSummarizer{} = cs, s: summarizer} ->
        load(cs, conversation, summarizer)
    end)
  end

  defp load(conversation_summarizer, conversation, summarizer),
    do:
      conversation_summarizer
      |> Map.put(:summarizer, summarizer)
      |> Map.put(:conversation, conversation)

  def broadcast_busy(%{conversation: conversation}) do
    conversation
    |> name()
    |> Atom.to_string()
    |> DiscussitWeb.Endpoint.broadcast("busy", nil)
  end

  def broadcast_idle(%{conversation: conversation}) do
    conversation
    |> name()
    |> Atom.to_string()
    |> DiscussitWeb.Endpoint.broadcast("idle", nil)
  end

  def name(%Conversation{id: id}), do: name(id)
  def name(id), do: :"conversation_#{id}"
end
