defmodule Discussit.Transcription do
  alias Discussit.Transcription.Support

  def start(struct, opts \\ []) do
    %{data: struct, status: :ok}
    |> Support.prepare_files()
    |> Support.start_transcribing(opts)
  end

  def finish(struct, account_id) do
    %{status: :ok, data: struct, message: ""}
    |> Support.finish_transcribing(account_id: account_id)
    |> Support.build_statement_attrs()
    |> Support.create_statements()
    |> Support.update_data()
    |> Support.prepare_return()
  end
end
