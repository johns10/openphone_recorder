defmodule Discussit.TopicAnalyzer.Local do
  @behaviour Discussit.TopicAnalyzer.Behaviour

  def init_model(statements, embeddings, %{model_path: model_path, openai_api_key: api_key}) do
    with {:ok, pid} <- start_python do
      topics =
        :python.call(pid, :topics, :init_model, [statements, embeddings, model_path, api_key])

      :python.stop(pid)
      {:ok, topics}
    end
  end

  def train_model(statements, embeddings, model_path) do
    with {:ok, pid} <- start_python do
      topics = :python.call(pid, :topics, :train_model, [statements, embeddings, model_path])

      :python.stop(pid)
      {:ok, topics}
    end
  end

  def get_topics(model_path) do
    with {:ok, pid} <- start_python do
      topics = :python.call(pid, :topics, :get_topics, [model_path])
      :python.stop(pid)
      {:ok, topics}
    end
  end

  def start_python() do
    path = [:code.priv_dir(:discussit), "python"] |> Path.join()
    :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}])
  end
end
