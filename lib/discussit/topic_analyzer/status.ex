defmodule Discussit.TopicAnalyzer.Status do
  import Ecto.Query
  alias Discussit.Repo

  def available?(account_id) do
    case all(account_id) do
      [_ | _] -> false
      [] -> true
    end
  end

  def all(account_id) do
    query =
      from(j in Oban.Job,
        where: fragment("(?->?)", j.args, "account_id") == ^account_id,
        where: j.queue == "topic_analyzer",
        where: j.state in ["available", "scheduled", "executing", "retryable"]
      )

    Repo.all(query)
  end
end
