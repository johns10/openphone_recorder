defmodule Mix.Tasks.AssignDefaultModelIdToSummarizers do
  @moduledoc "This task attempts to assign contact id's to participants"
  use Mix.Task

  import Ecto.Query
  alias Discussit.Summarizers
  alias Discussit.Summarizers.Summarizer
  alias Discussit.Repo

  def run(_) do
    Application.ensure_all_started(:discussit)

    query = from(p in Summarizer)
    stream = Repo.stream(query)

    Repo.transaction(fn ->
      Enum.map(stream, fn summarizer ->
        Summarizers.update_summarizer(summarizer, %{
          model_id: "41eaeafc-a41f-40ba-99ca-d47630cc71ae"
        })
      end)
    end)
  end
end
