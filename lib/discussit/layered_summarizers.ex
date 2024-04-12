defmodule Discussit.LayeredSummarizers do
  @moduledoc """
  The LayeredSummarizers context.
  """

  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.LayeredSummarizers.LayeredSummarizer

  def list_layered_summarizers do
    Repo.all(LayeredSummarizer)
  end

  def get_layered_summarizer!(id), do: Repo.get!(LayeredSummarizer, id)

  def create_layered_summarizer(attrs \\ %{}) do
    %LayeredSummarizer{}
    |> LayeredSummarizer.changeset(attrs)
    |> Repo.insert()
  end

  def update_layered_summarizer(%LayeredSummarizer{} = layered_summarizer, attrs) do
    layered_summarizer
    |> LayeredSummarizer.changeset(attrs)
    |> Repo.update()
  end

  def delete_layered_summarizer(%LayeredSummarizer{} = layered_summarizer) do
    Repo.delete(layered_summarizer)
  end

  def change_layered_summarizer(%LayeredSummarizer{} = layered_summarizer, attrs \\ %{}) do
    LayeredSummarizer.changeset(layered_summarizer, attrs)
  end
end
