defmodule DiscussitWeb.AdminLive.Index do
  alias Discussit.Summarizers
  alias Discussit.Summarizers.Summarizer
  use DiscussitWeb, :live_view

  alias Discussit.Events.Consumer

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true

  def handle_event("set_count", %{"count" => "infinity"}, socket) do
    Consumer.set_count(:inf)

    {:noreply, socket}
  end

  def handle_event("set_count", %{"count" => count}, socket) do
    count
    |> String.to_integer()
    |> Consumer.set_count()

    {:noreply, socket}
  end

  def handle_event("start", _, socket) do
    Consumer.start()

    {:noreply, socket}
  end

  def handle_event("seeds", _, socket) do
    Discussit.Init.generate_default_summarizers()

    {:noreply, socket}
  end

  def handle_event("assign_default_model_id_to_summarizers", _, socket) do
    import Ecto.Query
    alias Discussit.Repo

    query = from(p in Summarizer)
    stream = Repo.stream(query)

    Repo.transaction(fn ->
      Enum.map(stream, fn summarizer ->
        Summarizers.update_summarizer(summarizer, %{
          model_id: "41eaeafc-a41f-40ba-99ca-d47630cc71ae"
        })
      end)
    end)

    {:noreply, socket}
  end
end
