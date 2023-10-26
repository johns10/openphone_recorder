defmodule Discussit.TopicAnalyzer.Local do
  @behaviour Discussit.TopicAnalyzer.Behaviour

  def init_model(statements, account_id) do
    with {:ok, pid} <- start_python do
      topics = :python.call(pid, :topics, :init_model, [statements, account_id])
      :python.stop(pid)
      {:ok, topics}
    end
  end

  def train_model(statements, account_id) do
    with {:ok, pid} <- start_python do
      topics = :python.call(pid, :topics, :train_model, [statements, account_id])
      :python.stop(pid)
      {:ok, topics}
    end
  end

  def get_topics(account_id) do
    with {:ok, pid} <- start_python do
      topics = :python.call(pid, :topics, :get_topics, [account_id])
      :python.stop(pid)
      {:ok, topics}
    end
  end

  def start_python() do
    path = [:code.priv_dir(:discussit), "python"] |> Path.join()
    :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}])
  end
end
