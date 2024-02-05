defmodule Discussit.Transcription do
  @moduledoc """
  The Transcription context.
  """

  alias Discussit.Transcription.Support

  def transcribe(struct) do
    %{data: struct, status: :ok}
    |> Support.prepare_files()
    |> Support.start_transcribing()
  end
end
