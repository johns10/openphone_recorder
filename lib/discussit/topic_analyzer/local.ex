defmodule Discussit.TopicAnalyzer.Local do
  # @behaviour Discussit.TopicAnalyzer.Behaviour

  def init_model(pid, statements, embeddings, %{model_path: model_path, openai_api_key: api_key}) do
    :ok = :python.call(pid, :topics, :register_handler, [])

    Enum.zip(statements, embeddings)
    |> Enum.map(fn {e, s} -> :python.cast(pid, {:save_item, e, s}) end)

    topics = :python.call(pid, :topics, :init_model, [model_path, api_key])

    {:ok, topics}
  end

  def train_model(pid, statements, embeddings, model_path) do
    topics = :python.call(pid, :topics, :train_model, [statements, embeddings, model_path])

    {:ok, topics}
  end

  def get_topics(pid, model_path) do
    topics = :python.call(pid, :topics, :get_topics, [model_path])
    {:ok, topics}
  end

  def regenerate_labels(pid, model_path) do
    topics = :python.call(pid, :topics, :regenerate_labels, [model_path])
    {:ok, topics}
  end

  def start() do
    cwd = File.cwd!()
    path = [:code.priv_dir(:discussit), "python"] |> Path.join()
    File.cd!(path)
    # pid = spawn(fn -> MuonTrap.cmd("flask", ["--app", "topics_server", "run"]) end)
    File.cd!(cwd)

    {:ok, nil}
  end

  def stop(pid) do
    :python.stop(pid)
  end
end
