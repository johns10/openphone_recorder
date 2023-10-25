defmodule Discussit.Topics do
  @moduledoc """
  The Topics context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Topics.Topic

  def list_topics(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Topic
    |> filter_by_account_id(filters[:account_id])
    |> Repo.all()
  end

  def get_topic!(id), do: Repo.get!(Topic, id)

  defp filter_by_account_id(query, nil), do: query
  defp filter_by_account_id(query, account_id), do: where(query, [c], c.account_id == ^account_id)

  def create_topic(attrs \\ %{}) do
    %Topic{}
    |> Topic.changeset(attrs)
    |> Repo.insert()
  end

  def update_topic(%Topic{} = topic, attrs) do
    topic
    |> Topic.changeset(attrs)
    |> Repo.update()
  end

  def delete_topic(%Topic{} = topic) do
    Repo.delete(topic)
  end

  def change_topic(%Topic{} = topic, attrs \\ %{}) do
    Topic.changeset(topic, attrs)
  end
end
