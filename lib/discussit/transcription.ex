defmodule Discussit.Transcription do
  @moduledoc """
  The Transcription context.
  """

  alias Discussit.Transcription.Support

  def transcribe(ids, type, opts) do
    ids
    |> Flow.from_enumerable()
    |> Flow.map(&Support.get_data(&1, type, opts))
    |> Flow.map(&Support.prepare_files/1)
    |> Flow.map(&Support.transcribe(&1, opts))
    |> Flow.map(&Support.ignore_segments/1)
    |> Flow.map(&Support.build_statement_attrs/1)
    |> Flow.map(&Support.group_statement_attrs/1)
    |> Flow.map(&Support.create_statements/1)
    |> Flow.map(&Support.update_data(&1, opts))
    |> Enum.map(&Support.prepare_return/1)
  end
end
