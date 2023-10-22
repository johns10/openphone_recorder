defmodule Discussit.Embeddings.Server do
  defstruct queue: [], model_status: :not_started
  use GenServer
  alias Discussit.Embeddings.Impl

  def start_link(opts) do
    name = Map.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: name)
  end

  def start_embedding(), do: GenServer.cast(__MODULE__, :start_embedding)
  def set_status(status), do: GenServer.cast(__MODULE__, {:set_status, status})

  def get_status(), do: GenServer.call(__MODULE__, :get_status)

  @impl true
  def init(_), do: {:ok, %__MODULE__{}}

  @impl true
  def handle_cast(:start_embedding, state), do: check_model(state)

  def handle_cast({:set_status, status}, state),
    do: {:noreply, %{state | model_status: status}}

  @impl true
  def handle_call(:get_status, _, %{model_status: status} = state), do: {:reply, status, state}

  @impl true
  def handle_info(:start_embedding, state), do: check_model(state)

  defp check_model(state) do
    case Impl.start_model() do
      :ok ->
        {:noreply, %{state | model_status: :started}, {:continue, :start_embedding}}

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
