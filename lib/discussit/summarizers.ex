defmodule Discussit.Summarizers do
  import Ecto.Query, warn: false
  alias Discussit.Repo

  alias Discussit.Summarizers.Summarizer

  def list_summarizers(opts \\ []) do
    filters = Keyword.get(opts, :filters, [])

    Summarizer
    |> filter_by_account_id(filters[:account_id])
    |> filter_by_nil_account_id(filters[:nil_account_id])
    |> Repo.all()
  end

  def get_summarizer!(id), do: Repo.get!(Summarizer, id)

  def get_summarizer_by!(filters \\ []) do
    Repo.get_by(Summarizer, filters)
  end

  defp filter_by_account_id(query, nil), do: query
  defp filter_by_account_id(query, account_id), do: where(query, [s], s.account_id == ^account_id)
  defp filter_by_nil_account_id(query, nil), do: query
  defp filter_by_nil_account_id(query, _), do: where(query, [s], is_nil(s.account_id))

  def create_summarizer(attrs \\ %{}) do
    %Summarizer{}
    |> Summarizer.changeset(attrs)
    |> Repo.insert()
  end

  def update_summarizer(%Summarizer{} = summarizer, attrs) do
    summarizer
    |> Summarizer.changeset(attrs)
    |> Repo.update()
  end

  def delete_summarizer(%Summarizer{} = summarizer) do
    Repo.delete(summarizer)
  end

  def change_summarizer(%Summarizer{} = summarizer, attrs \\ %{}) do
    Summarizer.changeset(summarizer, attrs)
  end
end
