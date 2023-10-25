defmodule Mix.Tasks.TestTopics do
  @moduledoc "This task attempts to assign contact id's to participants"
  use Mix.Task

  import Ecto.Query
  alias Discussit.Contacts
  alias Discussit.Participants
  alias Discussit.Accounts
  alias Discussit.Participants.Participant
  alias Discussit.Repo

  def run(_) do
    Application.ensure_all_started(:discussit)
    path = [:code.priv_dir(:discussit), "python"] |> Path.join()
    {:ok, pid} = :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}])

    [account] = Accounts.list_accounts()

    statements_content =
      Discussit.Statements.list_statements(preloads: [:embedding])
      |> Enum.filter(&(&1.all_stopwords != true))
      |> Enum.filter(&(&1.unprocessable != true))
      |> Enum.filter(&(String.length(&1.content) > 10))
      |> Enum.map(& &1.content)
      |> Enum.map(&IO.inspect/1)

    {first, rest} = Enum.split(statements_content, 10)

    # :python.call(pid, :topics, :init_model, [first, account.id])

    # :python.call(pid, :topics, :train_model, [rest, account.id])

    :python.call(pid, :topics, :get_topics, [account.id]) |> IO.inspect()

    :python.stop(pid)
    {:ok, nil}
  end
end
