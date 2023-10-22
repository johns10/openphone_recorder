defmodule Discussit.Embeddings.Server do
  defstruct queue: [], model_status: :not_started
  use GenServer
  alias Discussit.Embeddings.Impl

  def start_link(opts) do
    name = Map.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: name)
  end

  def start(), do: GenServer.cast(__MODULE__, :start)

  @impl true
  def init(_) do
    {:ok, %__MODULE__{}, {:continue, :start_model}}
  end

  @impl true
  def handle_continue(:start_model, state), do: start_model(state)

  @impl true
  def handle_cast(:start, %{model_status: :started} = state) do
    Impl.embed_statements(500)
    {:noreply, state}
  end

  def handle_cast(:start, state), do: {:noreply, state}

  @impl true
  def handle_info(:start_model, state), do: start_model(state)

  defp start_model(state) do
    case Impl.start_model() do
      :ok ->
        {:noreply, %{model_status: :started}}

      :error ->
        Process.send_after(self(), :start_model, 10000)
        {:noreply, state}
    end
  end
end
