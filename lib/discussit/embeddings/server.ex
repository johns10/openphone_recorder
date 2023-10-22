defmodule Discussit.Embeddings.Server do
  defstruct queue: []
  use GenServer
  alias Discussit.Embeddings.Impl

  def start_link(opts) do
    name = Map.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: name)
  end

  def start_embedding(), do: GenServer.cast(__MODULE__, :start_embedding)

  @impl true
  def init(_), do: {:ok, %__MODULE__{}, {:continue, :start_model}}

  @impl true
  def handle_continue(:start_model, state), do: start_model(state)
  def handle_continue(:start_embedding, state), do: start_embedding(state)

  @impl true
  def handle_cast(:start_embedding, state), do: check_model(state)

  @impl true
  def handle_info(:start_model, state), do: start_model(state)
  def handle_info(:start_embedding, state), do: check_model(state)

  defp start_model(state) do
    case Impl.start_model() do
      :ok ->
        {:noreply, state}

      :error ->
        Process.send_after(self(), :start_model, 10000)
        {:noreply, state}
    end
  end

  defp check_model(state) do
    case Impl.start_model() do
      :ok ->
        {:noreply, state, {:continue, :start_embedding}}

      :error ->
        Process.send_after(self(), :start_embedding, 10000)
        {:noreply, state}
    end
  end

  def start_embedding(state) do
    Impl.embed_statements(500)
    {:noreply, state}
  end
end
