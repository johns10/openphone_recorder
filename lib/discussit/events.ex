defmodule Discussit.Events do
  import Ecto.Query, warn: false
  alias Discussit.Repo
  alias Discussit.Events.Event

  def list_events(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Event
    |> maybe_filter_by_external_id(filters[:external_id])
    |> Repo.all()
  end

  defp maybe_filter_by_external_id(query, nil), do: query

  defp maybe_filter_by_external_id(query, external_id),
    do:
      where(query, [e], fragment("? -> 'data' -> 'object' ->> 'id' = ?", e.payload, ^external_id))

  def list_unprocessed_events do
    Repo.all(
      from e in Event,
        where: e.processed == false and e.skipped == false,
        limit: 2,
        order_by: [asc: e.id]
    )
  end

  def get_event!(id), do: Repo.get!(Event, id)

  def create_event(attrs \\ %{}) do
    %Event{}
    |> Event.changeset(attrs)
    |> Repo.insert()
  end

  def update_event(%Event{} = event, attrs) do
    event
    |> Event.changeset(attrs)
    |> Repo.update()
  end

  def delete_event(%Event{} = event) do
    Repo.delete(event)
  end

  def change_event(%Event{} = event, attrs \\ %{}) do
    Event.changeset(event, attrs)
  end

  alias Discussit.Events.Openphone.Helpers

  def cast_event(%{"type" => type} = attrs) do
    module = Helpers.cast_module_name(type)

    attrs =
      attrs
      |> Helpers.snake_cased_map_keys()
      |> Helpers.rehome_data()

    struct(module)
    |> Helpers.changeset(attrs)
    |> Ecto.Changeset.apply_action!(:insert)
  end
end
