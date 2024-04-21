defmodule Discussit.Events.Consumer do
  alias Discussit.Events.Openphone.Projector
  alias Discussit.Events
  require Logger

  def consume_all() do
    case consume() do
      {:error, :empty} -> :ok
      {:ok, _} -> consume()
    end
  end

  def consume() do
    Events.list_top_unprocessed_event()
    |> case do
      [event] ->
        Logger.info("Processing event #{event.id} #{inspect(event)}")
        consume_event(event)

      [] ->
        Logger.info("No events in database.")
        {:error, :empty}
    end
  end

  defp consume_event(event) do
    event.payload
    |> Events.cast_event()
    |> Projector.apply(event.account_id)
    |> case do
      {:ok, _} ->
        Discussit.Embeddings.Job.new(%{})
        |> Oban.insert()

        Discussit.Events.update_event(event, %{processed: true})

      {:error, error} ->
        Discussit.Events.update_event(event, %{skipped: true})
        Logger.error(inspect(error))
        {:error, error}
    end
  end
end
