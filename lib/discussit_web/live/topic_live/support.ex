defmodule DiscussitWeb.TopicLive.Support do
  use Phoenix.Component
  alias Discussit.Models

  def list_latest_models(account) do
    Models.list_models(
      order_by: [inserted_at: :desc],
      filters: [account_id: account.id],
      limit: 2
    )
    |> case do
      [latest, last] -> [latest, last]
      [latest] -> [latest, nil]
      [] -> [nil, nil]
    end
  end

  def nest_topics(topics) do
    topics
    |> layers()
    |> Enum.reverse()
    |> nest()
  end

  defp layers(topics) do
    {root, remaining} = Enum.split_with(topics, &(&1.parent_id == nil))
    do_layers(root, remaining)
  end

  defp do_layers([], _), do: raise("shouldn't get here")

  defp do_layers(current, []) do
    [current]
  end

  defp do_layers(current, remaining) do
    ids = Enum.map(current, & &1.id)
    {next, remaining} = Enum.split_with(remaining, &(&1.parent_id in ids))
    [current | do_layers(next, remaining)]
  end

  defp nest([[root]]), do: root

  defp nest([last_layer, [root]]) do
    Map.put(root, :child_topics, last_layer)
  end

  defp nest([layer, next | rest]) do
    children = Enum.group_by(layer, & &1.parent_id)

    this =
      Enum.map(next, fn %{id: id} = topic ->
        case children[id] do
          nil -> topic
          children -> Map.put(topic, :child_topics, children)
        end
      end)

    nest([this | rest])
  end
end
