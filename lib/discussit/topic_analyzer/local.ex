defmodule Discussit.TopicAnalyzer.Local do
  # @behaviour Discussit.TopicAnalyzer.Behaviour
  require Logger

  def start() do
    Logger.info("#{__MODULE__} starting a python instance")
    path = [:code.priv_dir(:discussit), "python"] |> Path.join()
    :python.start([{:python_path, to_charlist(path)}, {:python, 'python3'}])
  end

  def start_server(pid) do
    IO.puts("start server called in elixir")
    %{'port' => port, 'status' => status} = :python.call(pid, :topics_server, :start_server, [])
    {:ok, %{port: port, status: status |> to_string() |> String.to_atom()}}
  end

  def stop_server(pid) do
    stop(pid)
    start()
  end

  def stop(pid) do
    :python.stop(pid)
  end
end
