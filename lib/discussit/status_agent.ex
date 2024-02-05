defmodule Discussit.StatusAgent do
  use Agent
  alias Discussit.Calls.Call
  alias Discussit.StatusRegistry
  alias Discussit.ConversationSummarizers.ConversationSummarizer

  def new(name) do
    {:ok, pid} =
      case Agent.start_link(fn -> :not_started end, name: name) do
        {:ok, pid} -> {:ok, pid}
        {:error, {:already_started, pid}} -> {:ok, pid}
      end

    case Registry.register(StatusRegistry, name, pid) do
      {:ok, _} -> {:ok, name}
      {:error, {:already_registered, _pid}} -> {:ok, name}
    end
  end

  def get(name) do
    case lookup(name) do
      {:ok, nil} -> {:ok, :not_started}
      {:ok, pid} -> {:ok, Agent.get(pid, & &1)}
    end
  end

  def set(name, state) do
    with {:ok, pid} when not is_nil(pid) <- lookup(name),
         :ok <- Agent.update(pid, fn _ -> state end) do
      DiscussitWeb.Endpoint.broadcast(Atom.to_string(name), "status_update", state)

      {:ok, state}
    else
      {:ok, nil} -> {:error, :not_started}
    end
  end

  def terminate(name) do
    with {:ok, pid} when not is_nil(pid) <- lookup(name),
         true <- Process.exit(pid, :kill),
         :ok <- Registry.unregister(StatusRegistry, name) do
      {:ok, :terminated}
    else
      {:ok, nil} -> {:ok, :terminated}
      false -> {:ok, :terminated}
    end
  end

  def unlink(name) do
    with {:ok, pid} when not is_nil(pid) <- lookup(name),
         true <- Process.unlink(pid) do
      {:ok, :unlinked}
    else
      {:ok, nil} -> {:ok, :unlinked}
      false -> {:ok, :unlinked}
    end
  end

  def alive?(name) do
    case lookup(name) do
      {:ok, nil} -> false
      {:ok, pid} -> Process.alive?(pid)
    end
  end

  defp lookup(name) do
    case Registry.lookup(StatusRegistry, name) do
      [{_, pid}] -> {:ok, pid}
      [] -> {:ok, nil}
    end
  end

  def name(%ConversationSummarizer{id: id}),
    do: :"conversation_summarizer_#{id}"

  def transcriber_name(%Call{id: id}), do: :"call_transcriber_#{id}"
end
