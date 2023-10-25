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
  def init(_), do: {:ok, %__MODULE__{}, {:continue, :check_model}}

  @impl true
  def handle_cast(:start_embedding, state), do: check_model(state)

  @impl true
  def handle_info(:start_embedding, state), do: check_model(state)

  @impl true
  def handle_continue(:start_embedding, state), do: start_embedding(state)
  def handle_continue(:check_model, state), do: check_model(state)

  defp check_model(state) do
    case Impl.start_model() do
      :ok ->
        Discussit.Embeddings.ModelStatus.set(:started)
        {:noreply, state, {:continue, :start_embedding}}

      :error ->
        Discussit.Embeddings.ModelStatus.set(:not_started)
        Process.send_after(self(), :start_embedding, 10000)
        {:noreply, state}
    end
  end

  def start_embedding(state) do
    Impl.embed_statements(50)
    {:noreply, state}
  end
end
